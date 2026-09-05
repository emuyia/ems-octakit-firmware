const LOCAL_FILE_SIGNATURE = 0x04034b50;
const CENTRAL_FILE_SIGNATURE = 0x02014b50;
const END_OF_CENTRAL_DIRECTORY_SIGNATURE = 0x06054b50;
const MAX_EOCD_SEARCH = 0xffff + 22;
export const MAX_SYSEX_SIZE = 2 * 1024 * 1024;

let crcTable;

function requireRange(bytes, offset, length, label) {
  if (offset < 0 || length < 0 || offset + length > bytes.byteLength) {
    throw new Error(`${label} extends past the ZIP file`);
  }
}

function dataView(bytes) {
  return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
}

function readU16(view, offset) {
  return view.getUint16(offset, true);
}

function readU32(view, offset) {
  return view.getUint32(offset, true);
}

function decodeName(bytes, utf8) {
  if (!utf8 && bytes.some((byte) => byte > 0x7f)) {
    throw new Error("non-ASCII legacy ZIP filenames are unsupported");
  }
  return new TextDecoder(utf8 ? "utf-8" : "ascii", { fatal: true }).decode(
    bytes,
  );
}

function getCrcTable() {
  if (crcTable) return crcTable;
  crcTable = new Uint32Array(256);
  for (let index = 0; index < 256; index += 1) {
    let value = index;
    for (let bit = 0; bit < 8; bit += 1) {
      value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
    }
    crcTable[index] = value >>> 0;
  }
  return crcTable;
}

export function crc32(bytes) {
  const table = getCrcTable();
  let value = 0xffffffff;
  for (const byte of bytes) {
    value = table[(value ^ byte) & 0xff] ^ (value >>> 8);
  }
  return (value ^ 0xffffffff) >>> 0;
}

export function isZip(bytes) {
  if (bytes.byteLength < 4) return false;
  return dataView(bytes).getUint32(0, true) === LOCAL_FILE_SIGNATURE;
}

function findEndOfCentralDirectory(bytes) {
  const view = dataView(bytes);
  const minimum = Math.max(0, bytes.byteLength - MAX_EOCD_SEARCH);
  for (let offset = bytes.byteLength - 22; offset >= minimum; offset -= 1) {
    if (readU32(view, offset) !== END_OF_CENTRAL_DIRECTORY_SIGNATURE) {
      continue;
    }
    const commentLength = readU16(view, offset + 20);
    if (offset + 22 + commentLength === bytes.byteLength) {
      return offset;
    }
  }
  throw new Error("ZIP end-of-central-directory record was not found");
}

function readCentralDirectory(bytes) {
  const view = dataView(bytes);
  const eocd = findEndOfCentralDirectory(bytes);
  const diskNumber = readU16(view, eocd + 4);
  const directoryDisk = readU16(view, eocd + 6);
  const diskEntries = readU16(view, eocd + 8);
  const totalEntries = readU16(view, eocd + 10);
  const directorySize = readU32(view, eocd + 12);
  const directoryOffset = readU32(view, eocd + 16);
  if (
    diskNumber !== 0 ||
    directoryDisk !== 0 ||
    diskEntries !== totalEntries
  ) {
    throw new Error("multi-disk ZIP archives are unsupported");
  }
  if (
    totalEntries === 0xffff ||
    directorySize === 0xffffffff ||
    directoryOffset === 0xffffffff
  ) {
    throw new Error("ZIP64 archives are unsupported");
  }
  requireRange(bytes, directoryOffset, directorySize, "central directory");
  if (directoryOffset + directorySize > eocd) {
    throw new Error("ZIP central directory overlaps its end record");
  }

  const entries = [];
  let offset = directoryOffset;
  for (let index = 0; index < totalEntries; index += 1) {
    requireRange(bytes, offset, 46, `central entry ${index}`);
    if (readU32(view, offset) !== CENTRAL_FILE_SIGNATURE) {
      throw new Error(`central entry ${index} has an invalid signature`);
    }
    const flags = readU16(view, offset + 8);
    const method = readU16(view, offset + 10);
    const expectedCrc = readU32(view, offset + 16);
    const compressedSize = readU32(view, offset + 20);
    const uncompressedSize = readU32(view, offset + 24);
    const nameLength = readU16(view, offset + 28);
    const extraLength = readU16(view, offset + 30);
    const commentLength = readU16(view, offset + 32);
    const startDisk = readU16(view, offset + 34);
    const localOffset = readU32(view, offset + 42);
    const entryLength = 46 + nameLength + extraLength + commentLength;
    requireRange(bytes, offset, entryLength, `central entry ${index}`);
    if (flags & 1) throw new Error("encrypted ZIP entries are unsupported");
    if (startDisk !== 0) throw new Error("split ZIP entries are unsupported");
    const name = decodeName(
      bytes.subarray(offset + 46, offset + 46 + nameLength),
      Boolean(flags & 0x0800),
    );
    entries.push({
      name,
      flags,
      method,
      expectedCrc,
      compressedSize,
      uncompressedSize,
      localOffset,
    });
    offset += entryLength;
  }
  if (offset !== directoryOffset + directorySize) {
    throw new Error("ZIP central-directory size differs from its entries");
  }
  return entries;
}

async function inflateRaw(bytes) {
  let stream;
  try {
    stream = new DecompressionStream("deflate-raw");
  } catch (error) {
    throw new Error(
      `this browser cannot decompress ZIP files locally: ${error.message}`,
    );
  }
  const decompressed = new Blob([bytes]).stream().pipeThrough(stream);
  return new Uint8Array(await new Response(decompressed).arrayBuffer());
}

async function extractEntry(archive, entry) {
  const view = dataView(archive);
  const offset = entry.localOffset;
  requireRange(archive, offset, 30, `local entry ${entry.name}`);
  if (readU32(view, offset) !== LOCAL_FILE_SIGNATURE) {
    throw new Error(`local entry ${entry.name} has an invalid signature`);
  }
  const localFlags = readU16(view, offset + 6);
  const localMethod = readU16(view, offset + 8);
  const nameLength = readU16(view, offset + 26);
  const extraLength = readU16(view, offset + 28);
  if (localFlags !== entry.flags || localMethod !== entry.method) {
    throw new Error(`local and central metadata differ for ${entry.name}`);
  }
  const dataOffset = offset + 30 + nameLength + extraLength;
  requireRange(archive, offset + 30, nameLength + extraLength, "local metadata");
  const localName = decodeName(
    archive.subarray(offset + 30, offset + 30 + nameLength),
    Boolean(localFlags & 0x0800),
  );
  if (localName !== entry.name) {
    throw new Error(`local and central filenames differ for ${entry.name}`);
  }
  requireRange(
    archive,
    dataOffset,
    entry.compressedSize,
    `compressed entry ${entry.name}`,
  );
  const compressed = archive.subarray(
    dataOffset,
    dataOffset + entry.compressedSize,
  );
  let output;
  if (entry.method === 0) {
    output = compressed.slice();
  } else if (entry.method === 8) {
    output = await inflateRaw(compressed);
  } else {
    throw new Error(
      `ZIP compression method ${entry.method} is unsupported for ${entry.name}`,
    );
  }
  if (output.byteLength !== entry.uncompressedSize) {
    throw new Error(
      `${entry.name} expanded to ${output.byteLength} bytes; expected ${entry.uncompressedSize}`,
    );
  }
  if (crc32(output) !== entry.expectedCrc) {
    throw new Error(`${entry.name} failed its ZIP CRC-32 check`);
  }
  return output;
}

export async function extractSingleSysex(archive) {
  const candidates = readCentralDirectory(archive).filter((entry) => {
    const lower = entry.name.toLowerCase();
    return lower.endsWith(".syx") && !lower.startsWith("__macosx/");
  });
  if (candidates.length !== 1) {
    throw new Error(
      `expected exactly one SysEx file in the ZIP, found ${candidates.length}`,
    );
  }
  const entry = candidates[0];
  if (
    entry.compressedSize > MAX_SYSEX_SIZE ||
    entry.uncompressedSize > MAX_SYSEX_SIZE
  ) {
    throw new Error("the ZIP SysEx member exceeds the local safety limit");
  }
  const bytes = await extractEntry(archive, entry);
  return { name: entry.name, bytes };
}
