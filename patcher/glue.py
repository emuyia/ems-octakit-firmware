LOAD_START = "async function __wbg_load("

SYNC_START = "function initSync("

ASYNC_START = "async function __wbg_init("

EXPORT_LINE = "export { initSync, __wbg_init as default };"

def strip_async_loader(source: str) -> str:
    load_start = source.find(LOAD_START)
    sync_start = source.find(SYNC_START, load_start)
    if load_start < 0 or sync_start < 0:
        raise ValueError("wasm-bindgen async load block was not found exactly")
    source = source[:load_start] + source[sync_start:]

    async_start = source.find(ASYNC_START)
    export_start = source.find(EXPORT_LINE, async_start)
    if async_start < 0 or export_start < 0:
        raise ValueError("wasm-bindgen async init block was not found exactly")
    export_end = export_start + len(EXPORT_LINE)
    source = source[:async_start] + "export { initSync };" + source[export_end:]

    if "fetch(" in source or "__wbg_init" in source or "__wbg_load" in source:
        raise ValueError("network-capable wasm-bindgen loader remains")
    return source
