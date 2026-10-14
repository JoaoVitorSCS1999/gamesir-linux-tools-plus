"""The Configure/Release overlay binds to state['config_phase'], not to the
wording of state['config_status'] (review Q9). Every status the reader sets
must therefore set its phase right after it, or the overlay shows the wrong
layout for that message."""
import ast
import os
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PHASES = {'', 'claiming', 'claimed', 'releasing', 'released', 'failed'}


def _assigned(node, key):
    if not (isinstance(node, ast.Assign) and len(node.targets) == 1):
        return False
    t = node.targets[0]
    return (isinstance(t, ast.Subscript) and isinstance(t.value, ast.Name)
            and t.value.id == 'state' and isinstance(t.slice, ast.Constant)
            and t.slice.value == key)


class ConfigPhaseTests(unittest.TestCase):
    def test_every_status_the_reader_sets_has_a_phase(self):
        for name in ('reader.py', 'bridge.py'):
            tree = ast.parse(open(os.path.join(ROOT, name)).read())
            for block in ast.walk(tree):
                body = getattr(block, 'body', None)
                if not isinstance(body, list):
                    continue
                for i, stmt in enumerate(body):
                    if not _assigned(stmt, 'config_status'):
                        continue
                    nxt = body[i + 1] if i + 1 < len(body) else None
                    with self.subTest(file=name, line=stmt.lineno):
                        self.assertTrue(nxt is not None and _assigned(nxt, 'config_phase'),
                                        'config_status set without config_phase after it')
                        v = nxt.value          # a constant, or `a if cond else b`
                        values = [v.body, v.orelse] if isinstance(v, ast.IfExp) else [v]
                        for c in values:
                            self.assertIsInstance(c, ast.Constant)
                            self.assertIn(c.value, PHASES)


if __name__ == '__main__':
    unittest.main()
