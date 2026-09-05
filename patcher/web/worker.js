import {
  build_firmware,
  initSync,
  recipe_metadata,
  validate_embedded_recipe,
} from './ot_patcher_wasm.js';
import { extractSingleSysex, isZip } from './ot_zip.js';

let recipeMetadata;
let outputFilename;
let initialized = false;
let busy = false;

const MAX_SELECTED_FILE_SIZE = 8 * 1024 * 1024;

function messageFor(error) {
  if (typeof error === 'string') return error;
  if (error && typeof error.message === 'string') return error.message;
  return String(error);
}

async function sha256Hex(bytes) {
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
}

function progress(stage, detail) {
  self.postMessage({ type: 'progress', stage, detail });
}

async function initialize(message) {
  if (initialized) throw new Error('patcher worker is already initialized');
  const engineBytes = message.assets?.engine;
  if (!(engineBytes instanceof ArrayBuffer)) {
    throw new Error('required patcher assets are missing');
  }

  initSync({ module: new Uint8Array(engineBytes) });
  validate_embedded_recipe();
  recipeMetadata = JSON.parse(recipe_metadata());
  const configuredOutputFilename = message.arguments?.outputFilename;
  outputFilename =
    configuredOutputFilename === undefined
      ? recipeMetadata.build.filename
      : configuredOutputFilename;
  if (
    typeof outputFilename !== 'string' ||
    recipeMetadata.build.filename !== outputFilename
  ) {
    throw new Error(
      'configured output filename differs from the embedded development build',
    );
  }

  initialized = true;
  self.postMessage({ type: 'ready', metadata: recipeMetadata });
}

async function build(message) {
  if (!initialized) throw new Error('patcher worker is not initialized');
  if (busy) throw new Error('another firmware build is already running');
  busy = true;
  try {
    const selectedFile = message.file;
    if (!selectedFile || typeof selectedFile.arrayBuffer !== 'function') {
      throw new Error('the selected local file could not be read');
    }
    if (selectedFile.size > MAX_SELECTED_FILE_SIZE) {
      throw new Error('the selected file exceeds the 8 MB local safety limit');
    }

    progress('Reading', 'Reading and hashing the selected local file');
    const selectedBytes = new Uint8Array(await selectedFile.arrayBuffer());
    const selectedSha256 = await sha256Hex(selectedBytes);
    const archiveInput = isZip(selectedBytes);
    let sysex = selectedBytes;
    let memberName = selectedFile.name;
    let memberSha256 = selectedSha256;
    let distributionVerified = false;

    if (archiveInput) {
      distributionVerified = recipeMetadata.source.distributions.some(
        (identity) =>
          identity.size === selectedBytes.byteLength &&
          identity.sha256 === selectedSha256,
      );
      progress('Extracting', 'Checking the local ZIP and extracting its SysEx');
      const extracted = await extractSingleSysex(selectedBytes);
      sysex = extracted.bytes;
      memberName = extracted.name;
      memberSha256 = await sha256Hex(sysex);
    }

    progress('Verifying', 'Authenticating official Octatrack OS 1.40C');
    await Promise.resolve();
    progress('Building', 'Applying, recompressing, and encoding locally');
    const artifact = build_firmware(sysex);
    let output;
    let report;
    try {
      output = artifact.sysex();
      report = JSON.parse(artifact.report_json);
    } finally {
      artifact.free();
    }
    progress('Auditing', 'Rechecking every generated firmware layer');
    await Promise.resolve();
    self.postMessage(
      {
        type: 'done',
        output: output.buffer,
        filename: outputFilename,
        report,
        input: {
          archive: archiveInput,
          distributionVerified,
          selectedSize: selectedBytes.byteLength,
          selectedSha256,
          memberName,
          memberSha256,
        },
      },
      [output.buffer],
    );
  } finally {
    busy = false;
  }
}

self.addEventListener('message', (event) => {
  const message = event.data;
  const operation =
    message?.type === 'init'
      ? initialize(message)
      : message?.type === 'patch'
        ? build(message)
        : Promise.reject(new Error('unknown patcher worker message'));
  operation.catch((error) => {
    self.postMessage({ type: 'error', message: messageFor(error) });
  });
});
