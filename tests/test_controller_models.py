"""Per-model protocol helpers (the 2026-10-14 controller review pass)."""
import unittest
from unittest.mock import patch

from vendors.gamesir.models.cyclone2 import factory, led, led_factory
from vendors.gamesir.models.g7_8k import led as led8k
from vendors.gamesir.models.g7pro import protocol as g7


class ControllerModelTests(unittest.TestCase):
    def test_8k_unknown_mode_and_sleep_select_nothing(self):
        # index 0 is "Off" in both lists: an unknown value must not look like it
        self.assertEqual(led8k.mode_index(0x03), led8k.MODES.index(('Rainbow', 0x03)))
        self.assertEqual(led8k.mode_index(0x02), -1)
        self.assertEqual(led8k.sleep_index(15), -1)

    def test_g7_firmware_text_needs_ascii_digits(self):
        self.assertEqual(g7.firmware_from_payload('0236'.encode('utf-16-le')), '2.3.6')
        self.assertIsNone(g7.firmware_from_payload('0²36'.encode('utf-16-le')))

    def test_g7_motion_decode_tolerates_a_short_blob(self):
        self.assertEqual(g7.decode_motion(b'\0' * 10), {})

    def test_restore_default_lighting_matches_the_profile_reset(self):
        # record 0 = the official app's reset capture (Flow), records 1-3 as read
        self.assertEqual(led.match_pattern(led_factory.FACTORY_DATA[:led.LED_REC]), 'Flow')
        self.assertEqual(led_factory.FACTORY_DATA[led.LED_REC:], led_factory._SNAPSHOT[led.LED_REC:])

    def test_profile_reset_reports_a_refused_write(self):
        calls = []
        def write(bank, addr, data, write_style=None, gen=None):
            calls.append(bank)
            return len(calls) < 3
        with patch.object(factory, 'write_reg', write):
            self.assertFalse(factory.restore_default_profile(2))
        with patch.object(factory, 'write_reg', lambda *a, **k: True):
            self.assertTrue(factory.restore_default_profile(2))

    def test_profile_reset_can_skip_the_shared_lighting(self):
        banks = []
        with patch.object(factory, 'write_reg', lambda b, *a, **k: banks.append(b) or True):
            factory.restore_default_profile(3, lighting=False)
        self.assertNotIn(0x20, banks)


if __name__ == '__main__':
    unittest.main()
