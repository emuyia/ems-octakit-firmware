import copy
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build import extract_stock, identity, patch_stock, read_stock


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.source = b"original synthetic data"
        self.patch = {"name": "example", "offset": 2, "length": 8,
                      "sha256": hashlib.sha256(self.source[2:10]).hexdigest(),
                      "writes": [{"offset": 4, "data": b"XY".hex()}]}

    def test_guard_checks_bytes_outside_the_changed_span(self):
        spec = {"patches": [self.patch]}
        self.assertEqual(patch_stock(self.source, spec), self.source[:4] + b"XY" + self.source[6:])
        changed = bytearray(self.source)
        changed[8] ^= 1
        with self.assertRaisesRegex(ValueError, "identity differs"):
            patch_stock(bytes(changed), spec)

    def test_full_guard_overlap_is_rejected(self):
        second = copy.deepcopy(self.patch)
        second["writes"] = [{"offset": 7, "data": "00"}]
        with self.assertRaisesRegex(ValueError, "guard spans overlap"):
            patch_stock(self.source, {"patches": [self.patch, second]})

    def test_write_must_stay_within_guard(self):
        self.patch["writes"] = [{"offset": 9, "data": "0000"}]
        with self.assertRaisesRegex(ValueError, "exceeds its guard"):
            patch_stock(self.source, {"patches": [self.patch]})

    def test_wrong_stock_is_rejected_before_building(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "wrong.syx"
            path.write_bytes(b"wrong")
            with self.assertRaisesRegex(ValueError, "official OS 1.40C"):
                read_stock(path, {"source": {"sysex": identity(self.source)}})

    def test_relocation_preserves_a_synthetic_call_destination(self):
        # Synthetic PC-relative call, not an instruction copied from firmware.
        source = (0x4eba).to_bytes(2, "big") + (20).to_bytes(2, "big")
        operation = {"kind": "m68k-relocate", "policy": "preserve-absolute-control-flow",
                     "source_offset": 0, "source_length": 4, "target_offset": 0,
                     "target_length": 6, "instruction_lengths": [4]}
        relocated = extract_stock(source, operation)
        self.assertEqual(relocated[:2], (0x4eb9).to_bytes(2, "big"))
        self.assertEqual(int.from_bytes(relocated[2:], "big"), 0x40000400 + 2 + 20)

    def test_extraction_rejects_invalid_geometry(self):
        operation = {"kind": "stock-copy", "policy": "exact-copy", "source_offset": 3,
                     "source_length": 10, "target_length": 10}
        with self.assertRaisesRegex(ValueError, "out of range"):
            extract_stock(b"test", operation)


if __name__ == "__main__":
    unittest.main()
