import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [stock, assets] = process.argv.slice(2);
if (!stock || !assets || process.argv.length !== 4) {
  throw new Error('usage: node tests/verify_web.mjs STOCK.syx WEB_BUILD_DIR');
}
const { initSync, build_firmware, recipe_metadata } = await import(
  pathToFileURL(resolve(assets, 'ot_patcher_wasm.js'))
);
initSync({ module: await readFile(resolve(assets, 'ot_patcher_wasm_bg.wasm')) });
const metadata = JSON.parse(recipe_metadata());
const artifact = build_firmware(await readFile(stock));
try {
  const result = artifact.sysex();
  assert.equal(result.length, metadata.output.sysex.size);
  assert.equal(createHash('sha256').update(result).digest('hex'), metadata.output.sysex.sha256);
  const report = JSON.parse(artifact.report_json);
  assert.ok(Object.values(report.verification).every((value) => value === true));
} finally {
  artifact.free();
}
assert.throws(() => build_firmware(new Uint8Array([1, 2, 3])));
console.log('WebAssembly output identity and wrong-input rejection verified.');
