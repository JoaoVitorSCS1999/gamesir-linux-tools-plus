"""Export and Restore switch the pad through its profiles, and a profile bank
only takes reads/writes while that profile is active. These tests check the
switch is CONFIRMED before a bank is touched, so a dropped switch can't read or
write the wrong profile. No hardware: a fake pad behind patched control calls."""
import os
import tempfile
import threading
import unittest
from unittest.mock import patch

import backup
import controller_profile as profiles
from gs_state import state
from vendors.gamesir import control


class FakePad:
    """Profile banks answer only while active; `stuck` profiles ignore switches."""

    def __init__(self):
        self.mem, self.results, self.stuck = {}, {}, set()
        self.written_while = []          # (bank, active profile) per write

    def set_profile(self, n, gen=None):
        if n not in self.stuck:
            state['profile'] = n         # what the reader would publish
        return True

    def write_reg(self, bank, addr, data, write_style=None, gen=None):
        self.written_while.append((bank, state.get('profile')))
        if bank in (1, 2, 3, 4) and bank != state.get('profile'):
            return True                  # dropped: bank isn't the active profile
        for i, v in enumerate(data):
            self.mem[(bank, addr + i)] = v
        return True

    def request_regs(self, reqs):
        for bank, addr, ln in reqs:
            if bank in (1, 2, 3, 4) and bank != state.get('profile'):
                continue                 # no reply for an inactive profile
            self.results[(bank, addr)] = [self.mem.get((bank, addr + i), bank) for i in range(ln)]

    def reg_result(self, bank, addr):
        return self.results.get((bank, addr))

    def clear(self, *_a, **_k):
        self.results.clear()


class BackupProfileSwitchTests(unittest.TestCase):
    def setUp(self):
        self.old = profiles.active()
        profiles.set_active(profiles.CYCLONE)
        self.pad = FakePad()
        self.tmp = tempfile.TemporaryDirectory()
        self.patches = [
            patch.dict(state, profile=1, connected=True),
            patch.object(control, 'set_profile', self.pad.set_profile),
            patch.object(control, 'write_reg', self.pad.write_reg),
            patch.object(control, 'request_regs', self.pad.request_regs),
            patch.object(control, 'reg_result', self.pad.reg_result),
            patch.object(backup, 'PROFILE_CONFIRM', 0.05),
            patch.object(backup, 'PROFILE_SETTLE', 0.0),
            patch.object(backup, 'READ_TIMEOUT', 0.3),
        ]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in reversed(self.patches):
            p.stop()
        profiles.set_active(self.old)
        self.tmp.cleanup()

    def run_and_wait(self, fn, *args):
        done, out = threading.Event(), {}
        def fin(ok, msg):
            out.update(ok=ok, msg=msg)
            done.set()
        with patch.object(threading.Thread, 'start', lambda t: t.run()):
            fn(*args, on_done=fin)
        self.assertTrue(done.wait(5))
        return out

    def test_switch_is_confirmed_and_resent(self):
        self.assertTrue(backup._switch_profile(3))
        self.assertEqual(state['profile'], 3)
        self.pad.stuck.add(2)
        self.assertFalse(backup._switch_profile(2))
        self.assertEqual(state['profile'], 3)

    def test_export_refuses_when_a_profile_wont_switch(self):
        self.pad.stuck.add(3)
        path = os.path.join(self.tmp.name, 'b.json')
        out = self.run_and_wait(backup.export_async, path)
        self.assertFalse(out['ok'])
        self.assertIn("didn't switch to profile 3", out['msg'])
        self.assertFalse(os.path.exists(path))
        self.assertEqual(state['profile'], 1)              # put back where it was

    def test_restore_never_writes_a_profile_it_couldnt_select(self):
        path = os.path.join(self.tmp.name, 'b.json')
        self.assertTrue(self.run_and_wait(backup.export_async, path)['ok'])
        data = backup.load(path)
        self.pad.stuck.add(2)
        self.pad.written_while.clear()
        out = self.run_and_wait(backup.apply_backup, data)
        self.assertFalse(out['ok'])
        self.assertIn("didn't switch to profile 2", out['msg'])
        for bank, active in self.pad.written_while:
            if bank in (1, 2, 3, 4):
                self.assertEqual(bank, active, 'a profile bank was written while another was active')
        self.assertNotIn(2, {b for b, _a in self.pad.written_while})
        self.assertEqual(state['profile'], 1)

    def test_restore_succeeds_when_every_switch_lands(self):
        path = os.path.join(self.tmp.name, 'b.json')
        self.assertTrue(self.run_and_wait(backup.export_async, path)['ok'])
        out = self.run_and_wait(backup.apply_backup, backup.load(path))
        self.assertTrue(out['ok'], out['msg'])
        self.assertEqual(state['profile'], 1)

    # --- schema: a raw export must be restorable (it was stamped 4, the G7 Pro's
    # number, from Sept 3 to Oct 14 2026 and restore then refused it) ----------
    def test_export_is_a_raw_schema_3_backup(self):
        path = os.path.join(self.tmp.name, 'b.json')
        self.assertTrue(self.run_and_wait(backup.export_async, path)['ok'])
        self.assertEqual(backup.load(path)['schema'], 3)

    def test_a_mislabelled_schema_4_raw_backup_still_restores(self):
        path = os.path.join(self.tmp.name, 'b.json')
        self.assertTrue(self.run_and_wait(backup.export_async, path)['ok'])
        data = backup.load(path)
        data['schema'] = 4                       # as exported Sept 3 - Oct 14
        self.assertFalse(backup._is_g7_semantic(data))
        out = self.run_and_wait(backup.apply_backup, data)
        self.assertTrue(out['ok'], out['msg'])

    def test_a_real_g7_backup_still_goes_to_the_g7_path(self):
        g7 = {'schema': 4, 'device': profiles.G7_PRO.name,
              'profiles': {'1': {'vib_l': 50, 'poll': 2}}, 'lighting': {}}
        self.assertTrue(backup._is_g7_semantic(g7))
        with self.assertRaisesRegex(ValueError, 'G7 Pro'):
            backup.apply_backup(g7)               # a Cyclone is connected


if __name__ == '__main__':
    unittest.main()
