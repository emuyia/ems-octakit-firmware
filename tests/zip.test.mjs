import assert from "node:assert/strict";
import { deflateRawSync } from "node:zlib";
import test from "node:test";

import {
  crc32,
  extractSingleSysex,
  isZip,
  MAX_SYSEX_SIZE,
} from "../patcher/web/ot_zip.js";

function u16(value) {
  const bytes = Buffer.alloc(2);
  bytes.writeUInt16LE(value);
  return bytes;
}

function u32(value) {
  const bytes = Buffer.alloc(4);
  bytes.writeUInt32LE(value >>> 0);
  return bytes;
}

function makeZip(
  name,
  contents,
  method = 8,
  declaredUncompressedSize = contents.length,
) {
  const nameBytes = Buffer.from(name, "utf8");
  const raw = Buffer.from(contents);
  const compressed = method === 8 ? deflateRawSync(raw) : raw;
  const checksum = crc32(raw);
  const flags = 0x0800;
  const local = Buffer.concat([
    u32(0x04034b50),
    u16(20),
    u16(flags),
    u16(method),
    u16(0),
    u16(0),
    u32(checksum),
    u32(compressed.length),
    u32(declaredUncompressedSize),
    u16(nameBytes.length),
    u16(0),
    nameBytes,
    compressed,
  ]);
  const central = Buffer.concat([
    u32(0x02014b50),
    u16(20),
    u16(20),
    u16(flags),
    u16(method),
    u16(0),
    u16(0),
    u32(checksum),
    u32(compressed.length),
    u32(declaredUncompressedSize),
    u16(nameBytes.length),
    u16(0),
    u16(0),
    u16(0),
    u16(0),
    u32(0),
    u32(0),
    nameBytes,
  ]);
  const end = Buffer.concat([
    u32(0x06054b50),
    u16(0),
    u16(0),
    u16(1),
    u16(1),
    u32(central.length),
    u32(local.length),
    u16(0),
  ]);
  return Buffer.concat([local, central, end]);
}

for (const method of [0, 8]) {
  test(`extracts one method-${method} SysEx and verifies its CRC`, async () => {
    const expected = Buffer.from([0xf0, 0x00, 0x20, 0x3c, 0xf7]);
    const archive = makeZip("OCTATRACK_OS1.40C.syx", expected, method);
    assert.equal(isZip(archive), true);
    const extracted = await extractSingleSysex(archive);
    assert.equal(extracted.name, "OCTATRACK_OS1.40C.syx");
    assert.deepEqual(Buffer.from(extracted.bytes), expected);
  });
}

test("rejects an archive whose compressed contents are corrupted", async () => {
  const archive = makeZip(
    "OCTATRACK_OS1.40C.syx",
    Buffer.from([0xf0, 0x00, 0x20, 0x3c, 0xf7]),
    0,
  );
  archive[archive.indexOf(0xf0)] ^= 1;
  await assert.rejects(extractSingleSysex(archive), /CRC-32/);
});

test("rejects a ZIP with no SysEx member", async () => {
  const archive = makeZip("readme.txt", Buffer.from("not firmware"), 8);
  await assert.rejects(extractSingleSysex(archive), /exactly one SysEx/);
});

test("rejects differing local and central filenames", async () => {
  const archive = makeZip(
    "OCTATRACK_OS1.40C.syx",
    Buffer.from([0xf0, 0xf7]),
    0,
  );
  archive[30] ^= 1;
  await assert.rejects(extractSingleSysex(archive), /filenames differ/);
});

test("rejects an oversized SysEx member before decompression", async () => {
  const archive = makeZip(
    "OCTATRACK_OS1.40C.syx",
    Buffer.from([0xf0, 0xf7]),
    8,
    MAX_SYSEX_SIZE + 1,
  );
  await assert.rejects(extractSingleSysex(archive), /safety limit/);
});
