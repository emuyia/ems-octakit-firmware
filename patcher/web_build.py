import base64
import json
import shutil

from audit import _load_reviews, audit_public_wasm, audit_static_assets
from glue import strip_async_loader


def build_web(root, work, out, cargo, env, recipe, payload, stock):
    from build import command, identity

    if command(["wasm-bindgen", "--version"], cwd=work).strip() != "wasm-bindgen 0.2.127":
        raise ValueError("wasm-bindgen CLI 0.2.127 is required")
    command([*cargo, "--lib", "--target", "wasm32-unknown-unknown", "--features", "embedded-recipe"], cwd=work, env=env)
    assets = work / "web"
    assets.mkdir(exist_ok=True)
    command(["wasm-bindgen", "--target", "web", "--no-typescript", "--remove-name-section",
             "--remove-producers-section", "--out-dir", assets, "--out-name", "ot_patcher_wasm",
             work / "cargo/wasm32-unknown-unknown/release/ot_patcher.wasm"], cwd=work)
    glue = assets / "ot_patcher_wasm.js"
    glue.write_text(strip_async_loader(glue.read_text()))
    for name in ("worker.js", "ot_zip.js", "client.js"):
        shutil.copyfile(root / "patcher/web" / name, assets / name)
    audit_recipe = json.loads(json.dumps(recipe))
    audit_recipe["public_payload"]["data"] = base64.b64encode(payload).decode("ascii")
    audit_recipe["public_payload"]["encoding"] = "base64"
    audit_recipe["provenance"]["public_payload_ledger"] = [{
        "payload_offset": 0, "length": len(payload), "provenance": "project-authored-source",
        "source": "verified source build with all stock operations removed",
    }]
    wasm = (assets / "ot_patcher_wasm_bg.wasm").read_bytes()
    reviews = _load_reviews(root / "patcher/wasm-review.json")
    filename, _, matches = audit_public_wasm(wasm, stock_os=stock, recipe=audit_recipe, reviews=reviews)
    audit_static_assets(assets)
    command(["node", root / "tests/verify_web.mjs", work / "stock.syx", assets], cwd=work)
    # Only audited browser assets cross out of the working directory.
    target = out / "web"
    target.mkdir(exist_ok=True)
    audit_static_assets(target)
    for name in ("ot_patcher_wasm.js", "ot_patcher_wasm_bg.wasm", "worker.js", "ot_zip.js", "client.js"):
        shutil.copyfile(assets / name, target / name)
    (out / "web-audit.json").write_text(json.dumps({
        "engine": identity(wasm), "filename": filename, "stock_match_reviews": matches,
    }, indent=2) + "\n")
