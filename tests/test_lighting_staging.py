"""Lighting edits are staged for Save like every other page, and Save writes
them through register_transaction (snapshot, write, read back, roll back).

No hardware: the controller is a dict of bank-0x20 bytes behind patched
control.write_reg / request_regs / reg_result."""
import os
import tempfile
import time
import unittest
from unittest.mock import patch

os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
from PySide6.QtGui import QGuiApplication
from bridge import GamesirBridge
import controller_profile as profiles
from gs_state import state
from vendors.gamesir import control
from vendors.gamesir.models.cyclone2 import led
from vendors.gamesir.models.g7_8k import led as led8k

SLOT = 2
REC = led.record_addr(SLOT)


class FakePad:
    """bank-0x20 register file; `drop` = addresses whose next write is lost."""

    def __init__(self):
        self.mem, self.results, self.drop, self.writes = {}, {}, set(), []

    def load(self, addr, data):
        for i, v in enumerate(data):
            self.mem[(0x20, addr + i)] = v

    def get(self, addr, n):
        return [self.mem.get((0x20, addr + i), 0) for i in range(n)]

    def write_reg(self, bank, addr, data, write_style=None, gen=None):
        self.writes.append((bank, addr, len(data)))
        if addr in self.drop:
            self.drop.discard(addr)
            return True                         # silently lost, like the real pad
        for i, v in enumerate(data):
            self.mem[(bank, addr + i)] = v
        return True

    def request_regs(self, reqs):
        for bank, addr, ln in reqs:
            assert ln <= 56, f'a {ln}-byte read is more than one reply carries'
            self.results[(bank, addr)] = [self.mem.get((bank, addr + i), 0) for i in range(ln)]

    def reg_result(self, bank, addr):
        return self.results.pop((bank, addr), None)


class LightingStagingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication([])

    def setUp(self):
        self.old = profiles.active()
        self.tmp = tempfile.TemporaryDirectory()
        self.pad = FakePad()
        self.patches = [
            patch.dict(state, selected='x', driving='x', connected=True, profile=1,
                       edit_profile=None, led_slot=None),
            patch.dict(os.environ, XDG_DATA_HOME=self.tmp.name),
            patch.object(control, 'write_reg', self.pad.write_reg),
            patch.object(control, 'request_regs', self.pad.request_regs),
            patch.object(control, 'reg_result', self.pad.reg_result),
        ]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in reversed(self.patches):
            p.stop()
        profiles.set_active(self.old)
        self.tmp.cleanup()

    def cyclone(self, record=None):
        profiles.set_active(profiles.CYCLONE)
        b = GamesirBridge()
        b._prof = profiles.CYCLONE
        b._driving = 'x'
        rec = record or led.pattern_record('Rainbow', 80)
        self.pad.load(REC, rec)
        self.pad.load(led.AUDIO_REACTIVE, [0])
        b._light_loaded = {REC: list(rec), led.AUDIO_REACTIVE: [0],
                           led.PICKUP_WAKE: [1], led.SLEEP_TIMEOUT: [5]}
        b._led_rec_slot = SLOT
        b._lighting_ui_from_staged()
        return b

    def save(self, b):
        b.applyConfig()
        end = time.monotonic() + 10
        while b._backup_busy and time.monotonic() < end:
            self.app.processEvents()
            time.sleep(0.01)
        self.app.processEvents()

    # --- staging -------------------------------------------------------------
    def test_reads_back_the_preset_on_the_pad(self):
        b = self.cyclone()
        self.assertEqual((b.currentPreset, b.brightness, b.pendingCount), ('Rainbow', 80, 0))

    def test_edits_stage_without_writing(self):
        b = self.cyclone()
        b.applyPreset('Pulse')
        b.setBrightness(40)
        self.assertEqual(b.currentPreset, 'Pulse')
        # one record write, but each setting the user touched counts on its own
        self.assertEqual(b.pendingList, ['Lighting profile 3 effect: Pulse',
                                         'Lighting profile 3 speed: 6',
                                         'Lighting profile 3 brightness: 40%'])
        self.assertEqual(b.pendingCount, 3)
        self.assertEqual(len(b._pending), 1)
        self.assertFalse(b.pendingHasProfileEdits)       # the button just says "Save"
        self.assertEqual(self.pad.writes, [])

    def test_an_edit_back_to_the_pads_value_is_no_change(self):
        b = self.cyclone()
        b.setAudioReactive(True)
        self.assertEqual(b.pendingCount, 1)
        b.setAudioReactive(False)
        self.assertEqual(b.pendingCount, 0)
        b.applyPreset('Pulse')
        b.applyPreset('Rainbow')
        self.assertEqual(b.pendingCount, 0)

    def test_discard_puts_the_page_back(self):
        b = self.cyclone()
        b.applyPreset('Alarm')
        b.lightsOff()
        self.assertEqual(b.currentPreset, 'Off')
        b.discardConfig()
        self.assertEqual((b.currentPreset, b.brightness, b.pendingCount), ('Rainbow', 80, 0))

    def test_custom_colours_are_not_a_preset(self):
        b = self.cyclone()
        b.applyKeyframes([[[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 255]]])
        self.assertEqual(b.currentPreset, '')
        self.assertEqual(b.pendingList, ['Lighting profile 3 effect: custom colours'])

    def test_profile_reload_keeps_staged_lighting(self):
        b = self.cyclone()
        b.applyPreset('Pulse')
        b._pending[(1, 0x10)] = {'addr': 0x10, 'bank': 1, 'data': [1], 'label': 'x', 'display': 'y'}
        b._drop_profile_pending()
        self.assertEqual(list(b._pending), [('light', REC)])
        self.assertEqual(b.currentPreset, 'Pulse')

    # --- saving --------------------------------------------------------------
    def test_save_writes_verifies_and_becomes_the_read_back(self):
        b = self.cyclone()
        b.applyPreset('Alarm')
        b.setBrightness(55)
        b.setAudioReactive(True)
        self.save(b)
        self.assertIn('Applied', b._apply_status)
        pad_rec = self.pad.get(REC, led.LED_REC)
        self.assertEqual((led.match_pattern(pad_rec), pad_rec[led.REC_BRIGHT_OFF]), ('Alarm', 55))
        self.assertEqual(self.pad.get(led.AUDIO_REACTIVE, 1), [1])
        self.assertEqual((b.pendingCount, b.currentPreset, b.brightness), (0, 'Alarm', 55))
        backups = os.listdir(os.path.join(self.tmp.name, 'deadband', 'controller-backups'))
        self.assertEqual(len(backups), 1)

    def test_a_dropped_write_is_resent_once(self):
        b = self.cyclone()
        b.setAudioReactive(True)
        self.pad.drop.add(led.AUDIO_REACTIVE)
        self.save(b)
        self.assertIn('Applied', b._apply_status)
        self.assertEqual(self.pad.get(led.AUDIO_REACTIVE, 1), [1])
        self.assertEqual(self.pad.writes.count((0x20, led.AUDIO_REACTIVE, 1)), 2)

    # --- the 8K ring ----------------------------------------------------------
    def test_8k_lighting_is_staged_and_discarded(self):
        profiles.set_active(profiles.G7_8K)
        b = GamesirBridge()
        b._prof = profiles.G7_8K
        b._light_loaded = {a: [0] * n for _b, a, n in led8k.read_fields()}
        b._light_loaded[led8k.BRIGHT] = [70]
        b._lighting_ui_from_staged()
        b.setLight8kBrightness(30)
        b.setLight8kQuads([0, 2], 120, 100)
        self.assertEqual(b.pendingCount, 3)
        self.assertEqual(self.pad.writes, [])
        b.discardConfig()
        self.assertEqual((b.light8kBrightness, b.pendingCount), (70, 0))


if __name__ == '__main__':
    unittest.main()
