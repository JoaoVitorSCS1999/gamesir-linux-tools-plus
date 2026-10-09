"""Captured G7 SE rate packets and controller-wide transactional Save behavior."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
from PySide6.QtCore import QTimer
from PySide6.QtGui import QGuiApplication
from bridge import GamesirBridge
import controller_profile as profiles
from gs_state import state
from vendors.gamesir import control
from vendors.gamesir.models.g7se import protocol as se


class RateProtocolTests(unittest.TestCase):
    def test_capture_writes_and_persistence(self):
        fixture = json.loads((Path(__file__).parent / 'fixtures/g7se-0630-rates.json').read_text())
        observed = set()
        for item in fixture['writes']:
            wire = bytes.fromhex(item['request'])
            self.assertEqual(se.rate_write(wire[2], item['bank'], [item['code']]), wire)
            self.assertTrue(se.allowed_app_request(wire))
            ack = bytes.fromhex(item['ack'])
            self.assertEqual(ack[2], wire[2])
            self.assertEqual(ack[4], 6)
            observed.add((item['bank'], item['code']))
        self.assertEqual(observed, {(b, c) for b in se.RATE_BANKS for c in range(3)})
        self.assertEqual(len(fixture['persistence']['reads']), 4)
        for item in fixture['persistence']['reads']:
            wire = bytes.fromhex(item['response'])
            offset = int.from_bytes(wire[6:8], 'big')
            data = se.match_read(wire, item['bank'], offset, wire[8])
            self.assertEqual(data[se.POLL_RATE - offset], 2)

    def test_only_exact_rate_and_remap_requests_allowed(self):
        for bank in se.RATE_BANKS:
            read = se.nexus_request(1, 5, bytes((4, bank, 0, se.POLL_RATE, 1)))
            self.assertTrue(se.allowed_app_request(read))
            wire = se.rate_write(1, bank, [2])
            for index, value in ((5, 5), (6, 1), (7, 55), (8, 2), (9, 3), (63, 1)):
                bad = bytearray(wire); bad[index] = value
                self.assertFalse(se.allowed_app_request(bad), (index, value))
            self.assertFalse(se.allowed_app_request(wire[:-1]))
            self.assertFalse(se.allowed_app_request(read[:-1]))
        for data in ([], [3], [255], [0, 1]):
            with self.assertRaises(ValueError):
                se.rate_write(1, 1, data)
        for bank in (0, 5, 0x20):
            with self.assertRaises(ValueError):
                se.rate_write(1, bank, [0])
        for address in (0xab, 0xc7):
            with self.assertRaises(ValueError):
                se.settings_write(1, 4, address, se.remap_record(15))
            self.assertFalse(se.allowed_setting_read(4, address, 8))
        for bank, addr, length in ((4, 0x35, 1), (4, 0x36, 2), (1, 0xab, 1), (5, 0x36, 1)):
            self.assertFalse(se.allowed_setting_read(bank, addr, length))


class RateAppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication([])

    def setUp(self):
        self.old = profiles.active()
        profiles.set_active(profiles.G7_SE)
        self.state_patch = patch.dict(state, selected='se', driving='se', connected=True,
            config_claimed=True, config_wanted=True, usb_bcd=se.TESTED_DESCRIPTOR,
            profile=1, edit_profile=1, demo=False)
        self.state_patch.start()
        self.bridge = GamesirBridge()
        for timer in self.bridge.findChildren(QTimer):
            timer.stop()
        self.memory = {(bank, se.POLL_RATE): [2] for bank in se.RATE_BANKS}
        self.memory.update({(1, a): list(se.remap_record(c)) for (_, a), c in zip(se.REMAP_SLOTS, (7, 8))})
        self.wires = []
        def write(wire):
            self.wires.append(wire)
            self.assertTrue(se.allowed_app_request(wire))
            if wire[3:5] == b'\x3c\x03':
                self.memory[wire[5], int.from_bytes(wire[6:8], 'big')] = list(wire[9:9+wire[8]])
            return len(wire)
        self.native_write = write
        self.handle = Mock(write=write)
        control.set_device(self.handle)
        self.bridge._driving = 'se'
        self.bridge._loaded_profile = 1
        self.bridge._config_generation = control.generation()
        self.bridge._config = {'remap': {'L4': 7, 'R4': 8}}
        self.load_rates()

    def tearDown(self):
        control.clear_device()
        profiles.set_active(self.old)
        self.state_patch.stop()
        self.bridge.deleteLater()

    def load_rates(self):
        self.bridge._se_rate_scope = None
        with patch.object(control, 'request_regs'), patch.object(control, 'reg_result',
                side_effect=lambda b, a: self.memory.get((b, a))):
            self.bridge._poll_se_rates()

    def save(self, read=None):
        self.recovery = []
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, XDG_DATA_HOME=directory), \
                patch.object(control, 'request_regs'), \
                patch.object(control, 'reg_result', side_effect=read or (lambda b, a: self.memory.get((b, a)))), \
                patch('bridge.threading.Thread', side_effect=lambda target, **kw: Mock(start=target)), \
                patch('bridge.time.sleep'):
            self.bridge.applyConfig()
            for path in Path(directory).rglob('before_apply_*.json'):
                self.recovery.append(json.loads(path.read_text()))

    def test_single_pending_edit_discard_and_revert(self):
        self.assertEqual(self.bridge.pollRates, ['250 Hz', '500 Hz', '1000 Hz'])
        self.assertTrue(self.bridge.pollRateEditable)
        self.bridge.setPoll(0)
        self.bridge.setPoll(1)
        self.assertEqual(self.bridge.pendingCount, 1)
        self.assertEqual(self.bridge.pollRateIndex, 1)
        self.bridge.setPoll(2)
        self.assertEqual(self.bridge.pendingCount, 0)
        self.bridge.setPoll(0)
        self.bridge.discardConfig()
        self.assertEqual(self.bridge.pollRateIndex, 2)
        self.assertEqual(self.wires, [])

    def test_profile_switch_discards_rate_and_bank_four_stays_hidden(self):
        self.bridge.setPoll(0)
        self.bridge.setProfile(2)
        self.bridge._poll_config()
        self.assertEqual(self.bridge.pendingCount, 0)
        self.assertFalse(self.bridge.pollRateEditable)
        self.assertEqual(self.bridge.pollRateIndex, -1)
        self.assertEqual(self.bridge.profileCount, 3)
        self.bridge.setProfile(4)
        self.assertEqual(state['edit_profile'], 2)

    def test_mixed_and_invalid_rate_loading_do_not_block_remaps(self):
        self.memory[2, se.POLL_RATE] = [0]
        self.load_rates()
        self.assertEqual(self.bridge.pollRateIndex, -1)
        self.assertEqual(self.bridge.pollRatePlaceholder, 'Mixed')
        self.assertTrue(self.bridge.pollRateEditable)
        self.bridge.setPoll(2)
        self.assertEqual(self.bridge.pendingCount, 1)
        self.bridge.discardConfig()
        for value in (None, [], [3], [1, 2]):
            with self.subTest(value=value):
                self.memory[2, se.POLL_RATE] = value
                self.load_rates()
                self.assertFalse(self.bridge.pollRateEditable)
                self.assertEqual(self.bridge.pollRateIndex, -1)
                self.bridge.setPoll(0)
                self.assertEqual(self.bridge.pendingCount, 0)
                self.bridge.setRemapCode('L4', 15)
                self.assertEqual(self.bridge.pendingCount, 1)
                self.bridge.discardConfig()

    def test_selection_session_firmware_and_busy_guards(self):
        for field, value in (('selected', 'other'), ('config_claimed', False), ('usb_bcd', 0x640)):
            with patch.dict(state, {field: value}):
                self.assertFalse(self.bridge.pollRateEditable)
                self.bridge.setPoll(0)
                self.assertEqual(self.bridge.pendingCount, 0)
        with patch.dict(state, usb_bcd=0x640):
            self.assertEqual(self.bridge.pollRates, [])
        self.bridge._backup_busy = True
        self.assertFalse(self.bridge.pollRateEditable)
        self.bridge.setPoll(0)
        self.bridge._backup_busy = False
        for index in (-1, 3, 1000):
            self.bridge.setPoll(index)
        self.assertEqual(self.bridge.pendingCount, 0)
        self.bridge.setPoll(0)
        control.set_device(self.handle)
        self.save()
        self.assertEqual(self.wires, [])
        self.assertIn('older session/profile', self.bridge._apply_status)

    def test_all_rates_write_four_banks_and_are_read_back(self):
        for code in range(3):
            with self.subTest(code=code):
                self.memory.update({(b, se.POLL_RATE): [(code+1) % 3] for b in se.RATE_BANKS})
                self.bridge._loaded_profile = 1
                self.load_rates()
                self.wires.clear()
                self.bridge.setPoll(code)
                self.save()
                self.assertEqual([w[5] for w in self.wires], list(se.RATE_BANKS))
                self.assertTrue(all(self.memory[b, se.POLL_RATE] == [code] for b in se.RATE_BANKS))
                self.assertIn('4/4 confirmed', self.bridge._apply_status)
                self.assertNotIn('reconnecting', self.bridge._apply_status)
                self.assertEqual(self.bridge.pendingCount, 0)
                self.assertEqual(set(self.recovery[0]['profiles']), {'1', '2', '3', '4'})

    def test_combined_save_remaps_precede_rate_writes(self):
        self.bridge.setPoll(0)
        self.bridge.setRemapCode('L4', 15)
        self.save()
        self.assertEqual([(w[5], int.from_bytes(w[6:8], 'big')) for w in self.wires],
                         [(1, 0xab)] + [(b, se.POLL_RATE) for b in se.RATE_BANKS])
        self.assertIn('5/5 confirmed', self.bridge._apply_status)

    def test_each_partial_failure_restores_distinct_originals(self):
        for failure_kind in ('write', 'read'):
            for failed_bank in se.RATE_BANKS:
                with self.subTest(kind=failure_kind, bank=failed_bank):
                    original = {b: [b % 2] for b in se.RATE_BANKS}
                    self.memory.update({(b, se.POLL_RATE): v[:] for b, v in original.items()})
                    self.bridge._pending.clear()
                    self.bridge._loaded_profile = 1
                    self.load_rates()
                    self.wires.clear()
                    self.bridge.setPoll(2)
                    failed = [False]
                    def write(wire):
                        count = self.native_write(wire)
                        if failure_kind == 'write' and wire[5] == failed_bank and not failed[0]:
                            failed[0] = True
                            return 0  # May have reached the controller despite short transfer.
                        return count
                    def read(bank, addr):
                        value = self.memory[bank, addr]
                        # persistent: Save re-sends a mismatched write once, so a
                        # one-off bad read-back recovers (see the test below)
                        if failure_kind == 'read' and bank == failed_bank and value == [2]:
                            failed[0] = True
                            return [0]
                        return value
                    self.handle.write = write
                    self.save(read)
                    self.assertEqual({b: self.memory[b, se.POLL_RATE] for b in se.RATE_BANKS}, original)
                    retry = [failed_bank] if failure_kind == 'read' else []
                    self.assertEqual([w[5] for w in self.wires],
                                     list(range(1, failed_bank+1)) + retry + list(range(failed_bank, 0, -1)))
                    self.assertIn('original settings restored and verified', self.bridge._apply_status)
                    self.assertEqual(self.bridge.pendingCount, 1)
                    self.assertEqual({int(b): f['0x0036']['bytes'] for b, f in self.recovery[0]['profiles'].items()}, original)

    def test_one_off_bad_readback_is_resent_and_saves(self):
        original = {b: [b % 2] for b in se.RATE_BANKS}
        self.memory.update({(b, se.POLL_RATE): v[:] for b, v in original.items()})
        self.bridge._pending.clear()
        self.bridge._loaded_profile = 1
        self.load_rates()
        self.wires.clear()
        self.bridge.setPoll(2)
        failed = [False]
        def read(bank, addr):
            value = self.memory[bank, addr]
            if bank == 2 and value == [2] and not failed[0]:
                failed[0] = True
                return [0]
            return value
        self.save(read)
        self.assertEqual({b: self.memory[b, se.POLL_RATE] for b in se.RATE_BANKS},
                         {b: [2] for b in se.RATE_BANKS})
        self.assertEqual([w[5] for w in self.wires], [1, 2, 2, 3, 4])
        self.assertIn('Applied', self.bridge._apply_status)

    def test_missing_rate_reply_releases_queue_for_remaps(self):
        self.bridge._se_rate_scope = None
        self.bridge._poll_se_rates()
        control.pump_reads()
        late = self.wires[-1]
        control.request_regs([(1, 0xab, 8)])
        self.bridge._se_rate_deadline = 0
        self.bridge._poll_se_rates()
        self.assertFalse(self.bridge.pollRateEditable)
        control.pump_reads()
        self.assertEqual(self.wires[-1][5:9], bytes((1, 0, 0xab, 8)))
        reply = bytes((16, 0, late[2], 60, 5)) + late[5:9] + b'\x02'
        self.assertFalse(control.store_se_reply(reply.ljust(64, b'\0')))
        self.bridge._poll_se_rates()
        self.assertEqual(len(self.wires), 2)

    def test_save_cancels_optional_rate_reads_before_snapshot(self):
        self.bridge._se_rate_scope = None
        self.bridge._poll_se_rates()
        control.pump_reads()
        self.wires.clear()
        self.bridge.setRemapCode('L4', 15)
        original_apply = __import__('register_transaction').apply
        def apply(*args, **kwargs):
            self.assertIsNone(control._inflight)
            self.assertFalse(control._read_q)
            return original_apply(*args, **kwargs)
        with patch('bridge.register_transaction.apply', side_effect=apply):
            self.save()
        self.assertIn('1/1 confirmed', self.bridge._apply_status)

    def test_qml_rate_binding_updates_on_stage_discard_and_session_changes(self):
        from PySide6.QtCore import QUrl
        from PySide6.QtQml import QQmlComponent, QQmlEngine
        engine = QQmlEngine()
        engine.rootContext().setContextProperty('bridge', self.bridge)
        component = QQmlComponent(engine)
        component.setData(b'''import QtQml
            QtObject {
                property int rate: bridge.pollRateIndex
                property bool editable: bridge.pollRateEditable
                property string placeholder: bridge.pollRatePlaceholder
            }''', QUrl())
        view = component.create()
        self.assertIsNotNone(view, component.errors())
        self.assertEqual(view.property('rate'), 2)
        self.bridge.setPoll(0)
        self.assertEqual(view.property('rate'), 0)
        self.bridge.discardConfig()
        self.assertEqual(view.property('rate'), 2)
        self.bridge._backup_busy = True
        self.bridge.backupBusyChanged.emit()
        self.assertFalse(view.property('editable'))
        self.bridge._backup_busy = False
        state['selected'] = 'replacement'
        self.bridge.controllersChanged.emit()
        self.assertEqual(view.property('rate'), -1)
        self.assertFalse(view.property('editable'))
        view.deleteLater()

    def test_other_controllers_keep_single_bank_unverified_rate_save(self):
        for prof in (profiles.G7_8K, profiles.TARANTULA_PRO_8K):
            profiles.set_active(prof)
            self.bridge._apply_profile(prof)
            self.bridge._config = {'poll': 2}
            self.bridge.setPoll(0)
            reads = []
            def read(bank, addr):
                reads.append((bank, addr))
                return [2]
            with patch.object(control, 'write_reg', return_value=True) as write, \
                    patch.object(control, 'set_profile', return_value=True):
                self.save(read)
            self.assertEqual(reads, [(1, prof.POLL_RATE)])
            write.assert_called_once_with(1, prof.POLL_RATE, [0], write_style=prof.write_style,
                                          gen=control.generation())
            self.assertIn('controller reconnecting', self.bridge._apply_status)

    def test_unknown_prewrite_original_prevents_all_writes(self):
        self.bridge.setPoll(0)
        self.memory[4, se.POLL_RATE] = [9]
        self.save()
        self.assertEqual(self.wires, [])
        self.assertIn('Unknown G7 SE report-rate', self.bridge._apply_status)

    def test_disconnect_keeps_recovery_and_never_writes_replacement(self):
        self.bridge.setPoll(0)
        def read(bank, addr):
            if self.wires:
                state['selected'] = 'replacement'
            return self.memory[bank, addr]
        self.save(read)
        self.assertEqual(len(self.wires), 1)
        self.assertEqual(len(self.recovery), 1)
        self.assertIn('recovery NOT confirmed', self.bridge._apply_status)


class RateToolTests(unittest.TestCase):
    def test_roundtrip_saves_durable_baseline_and_restores_after_failure(self):
        from tools import g7se_rates as tool
        for fail_at in (None, 0, 1, 2):
            with self.subTest(fail_at=fail_at), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'rate-test.json'
                baseline = {str(b): (bytes(54) + bytes((b % 2,)) + bytes(366)).hex()
                            for b in se.RATE_BANKS}
                current = [baseline]
                calls = []
                def save(root, expected, code, recovery):
                    self.assertEqual(json.loads(output.read_text())['baseline'], baseline)
                    calls.append(code)
                    current[0] = tool.expected_profiles(baseline, code)
                    if len(calls)-1 == fail_at:
                        raise OSError('injected Save failure')
                    return 'Applied 4/4'
                with patch.object(tool, 'identity', return_value={'devnum': '1'}), \
                        patch.object(tool, 'snapshots', side_effect=lambda *args: current[0]), \
                        patch.object(tool, 'app_save', side_effect=save), \
                        patch.object(tool, 'restore', return_value=True) as restore:
                    self.assertEqual(tool.run('/unused', output), fail_at is None)
                    restore.assert_called_once()
                self.assertEqual(len(calls), 3 if fail_at is None else fail_at+1)
                self.assertTrue(json.loads(output.read_text())['originals_restored'])
                with self.assertRaisesRegex(ValueError, 'overwrite'):
                    tool.run('/unused', output)

    def test_reconnect_is_read_only_and_requires_new_usb_session(self):
        from tools import g7se_rates as tool
        with tempfile.TemporaryDirectory() as directory:
            baseline = {str(b): bytes(se.PROFILE_SIZE).hex() for b in se.RATE_BANKS}
            source = Path(directory) / 'baseline.json'
            source.write_text(json.dumps({'identity': {'devnum': '1'}, 'baseline': baseline}))
            with patch.object(tool, 'identity', return_value={'devnum': '1'}), \
                    patch.object(tool, 'snapshots') as snapshot:
                with self.assertRaisesRegex(OSError, 'not been unplugged'):
                    tool.run('/unused', Path(directory)/'first.json', previous=source)
                snapshot.assert_not_called()
            with patch.object(tool, 'identity', return_value={'devnum': '2'}), \
                    patch.object(tool, 'snapshots', return_value=baseline), \
                    patch.object(tool, 'restore') as restore:
                self.assertTrue(tool.run('/unused', Path(directory)/'second.json', previous=source))
                restore.assert_not_called()


if __name__ == '__main__':
    unittest.main()
