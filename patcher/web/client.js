export function buildFirmware(file, engine, onProgress = () => {}) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL('./worker.js', import.meta.url), {
      type: 'module',
    });
    const fail = (error) => {
      worker.terminate();
      reject(error instanceof Error ? error : new Error(String(error)));
    };
    worker.onerror = (event) => fail(event.message);
    worker.onmessageerror = () => fail('Could not read patcher worker response');
    worker.onmessage = ({ data }) => {
      try {
        if (data.type === 'ready') {
          worker.postMessage({ type: 'patch', file });
        } else if (data.type === 'progress') {
          onProgress(data.stage, data.detail);
        } else if (data.type === 'done') {
          worker.terminate();
          resolve(data);
        } else if (data.type === 'error') {
          fail(data.message);
        }
      } catch (error) {
        fail(error);
      }
    };
    try {
      worker.postMessage({ type: 'init', assets: { engine } });
    } catch (error) {
      fail(error);
    }
  });
}
