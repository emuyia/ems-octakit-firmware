#!/usr/bin/env python3
"""Build Octakit from locally supplied official firmware."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "patcher"))
from embed import render_rust


def identity(data: bytes) -> dict:
    return {"size": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def verify(data: bytes, expected: dict, label: str) -> None:
    if identity(data) != {k: expected[k] for k in ("size", "sha256")}:
        raise ValueError(f"{label} identity differs")


def read_stock(path: Path, spec: dict) -> bytes:
    if path.stat().st_size > 8 * 1024 * 1024:
        raise ValueError("stock input exceeds 8 MiB")
    if path.suffix.lower() == ".zip":
        with ZipFile(path) as archive:
            members = [m for m in archive.infolist()
                       if m.filename.lower().endswith(".syx")
                       and not m.filename.startswith("__MACOSX/")]
            if len(members) != 1 or members[0].file_size != spec["source"]["sysex"]["size"]:
                raise ValueError("ZIP must contain one official-size SysEx")
            data = archive.read(members[0])
    else:
        data = path.read_bytes()
    verify(data, spec["source"]["sysex"], "official OS 1.40C SysEx")
    return data


def extract_stock(stock: bytes, operation: dict) -> bytes:
    start, length = operation["source_offset"], operation["source_length"]
    if start < 0 or length <= 0 or start + length > len(stock):
        raise ValueError("stock extraction is out of range")
    source = stock[start:start + length]
    if operation["kind"] == "stock-copy":
        if operation["policy"] != "exact-copy":
            raise ValueError("unsupported stock copy policy")
        result = source
    elif operation["kind"] == "m68k-relocate":
        lengths = operation["instruction_lengths"]
        policy = operation["policy"]
        if (any(n <= 0 or n % 2 for n in lengths) or sum(lengths) != length
                or policy not in ("preserve-encoding", "preserve-absolute-control-flow")):
            raise ValueError("invalid instruction relocation")
        output = bytearray()
        cursor = 0
        for n in lengths:
            instruction = source[cursor:cursor + n]
            opcode = int.from_bytes(instruction[:2], "big")
            if policy == "preserve-absolute-control-flow" and n == 4 and opcode in (0x4eba, 0x4efa):
                absolute = 0x40000400 + start + cursor + 2 + int.from_bytes(instruction[2:], "big", signed=True)
                displacement = absolute - (0x45d0dde0 + operation["target_offset"] + len(output) + 2)
                if -32768 <= displacement <= 32767:
                    output.extend(instruction[:2] + displacement.to_bytes(2, "big", signed=True))
                else:
                    output.extend((0x4eb9 if opcode == 0x4eba else 0x4ef9).to_bytes(2, "big"))
                    output.extend(absolute.to_bytes(4, "big"))
            else:
                output.extend(instruction)
            cursor += n
        result = bytes(output)
    else:
        raise ValueError("unsupported stock extraction")
    if len(result) != operation["target_length"]:
        raise ValueError("stock extraction length differs")
    return result


def patch_stock(stock: bytes, spec: dict) -> bytes:
    output = bytearray(stock)
    previous_end = 0
    for patch in sorted(spec["patches"], key=lambda p: p["offset"]):
        start, end = patch["offset"], patch["offset"] + patch["length"]
        if start < previous_end or end <= start or end > len(stock):
            raise ValueError("patch guard spans overlap or exceed the stock image")
        verify(stock[start:end], {"size": end - start, "sha256": patch["sha256"]}, patch["name"])
        write_end = start
        for write in patch["writes"]:
            pos = write["offset"]
            data = bytes.fromhex(write["data"])
            if not data or pos < write_end or pos + len(data) > end:
                raise ValueError("patch write exceeds its guard or overlaps another write")
            if any(a == b for a, b in zip(stock[pos:pos + len(data)], data)):
                raise ValueError("public patch retains unchanged stock bytes")
            output[pos:pos + len(data)] = data
            write_end = pos + len(data)
        previous_end = end
    return bytes(output)


def command(args: list, *, cwd: Path, env: dict | None = None) -> str:
    result = subprocess.run([str(x) for x in args], cwd=cwd, env=env, check=True,
                            stdout=subprocess.PIPE, text=True)
    return result.stdout


def make_recipe(spec: dict, runtime: bytes, append: bytes) -> tuple[dict, bytes]:
    recipe = copy.deepcopy(spec)
    for key in ("patches", "sources", "source_hashes", "interface_version", "compiler", "memory"):
        recipe.pop(key, None)
    payload = bytearray()
    operations = []
    for patch in spec["patches"]:
        for write in patch["writes"]:
            data = bytes.fromhex(write["data"])
            operations.append({"offset": write["offset"], "length": len(data), "payload_offset": len(payload)})
            payload.extend(data)
    recipe["operations"] = sorted(operations, key=lambda r: r["offset"])
    replacement_bytes = len(payload)
    for name in ("loader", "stage_header"):
        blob = recipe["append"][name]
        data = append[blob["target_offset"]:blob["target_offset"] + blob["length"]]
        verify(data, blob, name)
        blob["payload_offset"] = len(payload)
        payload.extend(data)
    ranges = []
    cursor = 0
    for operation in sorted(recipe["append"]["runtime"]["stock_operations"], key=lambda r: r["target_offset"]):
        start = operation["target_offset"]
        if start < cursor or start + operation["target_length"] > len(runtime):
            raise ValueError("runtime stock operations overlap or exceed runtime")
        if start > cursor:
            ranges.append({"target_offset": cursor, "length": start - cursor, "payload_offset": len(payload)})
            payload.extend(runtime[cursor:start])
        cursor = start + operation["target_length"]
    if cursor < len(runtime):
        ranges.append({"target_offset": cursor, "length": len(runtime) - cursor, "payload_offset": len(payload)})
        payload.extend(runtime[cursor:])
    recipe["append"]["runtime"]["public_ranges"] = ranges
    recipe["public_payload"] = {**identity(payload), "replacement_bytes": replacement_bytes}
    recipe["provenance"] = {
        "guard_or_original_byte_arrays_embedded": False,
        "stock_derived_payload_blobs_embedded": False,
        "replacement_encoding": "changed-bytes-only",
        "unchanged_source_bytes_in_replacements": 0,
        "omitted_unchanged_source_bytes": sum(p["length"] for p in spec["patches"]) - replacement_bytes,
        "append_origin": "authenticated-stock-local-reconstruction-v1",
        "stock_derived_expression_ranges": 0,
    }
    return recipe, bytes(payload)


def build(stock_path: Path, out: Path, web: bool = False) -> dict:
    spec = json.loads((ROOT / "runtime/firmware.json").read_text())
    if spec["interface_version"] != 1:
        raise ValueError("unsupported build interface")
    sysex = read_stock(stock_path, spec)
    out = out.resolve()
    if out == ROOT or (out.is_relative_to(ROOT) and not out.is_relative_to(ROOT / "build")):
        raise ValueError("output must be outside the checkout or under build/")
    out.mkdir(parents=True, exist_ok=True)
    work = out / ".work"
    work.mkdir(exist_ok=True)
    env = os.environ.copy()
    toolchain = env.get("OCTAKIT_RUST_TOOLCHAIN", "stable")
    env["RUSTC"] = command(["rustup", "which", "--toolchain", toolchain, "rustc"], cwd=work).strip()
    env["CARGO_TARGET_DIR"] = str(work / "cargo")
    env["CARGO_NET_OFFLINE"] = "true"
    flags = env.get("CARGO_ENCODED_RUSTFLAGS", "").split("\x1f") if env.get("CARGO_ENCODED_RUSTFLAGS") else shlex.split(env.get("RUSTFLAGS", ""))
    for path, name in [(ROOT, "/octakit"), (out, "/build"),
                       (Path(env.get("CARGO_HOME", Path.home() / ".cargo")), "/cargo"),
                       (Path(env.get("RUSTUP_HOME", Path.home() / ".rustup")), "/rustup")]:
        flags.append(f"--remap-path-prefix={path}={name}")
    env.pop("RUSTFLAGS", None)
    env["CARGO_ENCODED_RUSTFLAGS"] = "\x1f".join(flags)
    if not command([env["RUSTC"], "--version"], cwd=work).startswith("rustc 1.97.1 "):
        raise ValueError("Rust 1.97.1 is required")
    if command(["m68k-elf-gcc", "-dumpfullversion"], cwd=work).strip() != spec["compiler"]["gcc_version"]:
        raise ValueError("m68k-elf-gcc version differs from the source snapshot")
    cargo = ["cargo", "build", "--manifest-path", ROOT / "patcher/Cargo.toml", "--locked", "--offline", "--release"]
    command(cargo, cwd=work, env=env)
    native = work / "cargo/release/ot_patcher"
    stock_syx, stock_raw = work / "stock.syx", work / "stock.bin"
    stock_syx.write_bytes(sysex)
    command([native, "decode", stock_syx, stock_raw], cwd=work)
    stock = stock_raw.read_bytes()
    verify(stock, spec["source"]["os"], "decoded stock OS")
    patched = patch_stock(stock, spec)
    (work / "stock").mkdir(exist_ok=True)
    for i, operation in enumerate(spec["append"]["runtime"]["stock_operations"]):
        (work / "stock" / f"{i:04d}.bin").write_bytes(extract_stock(stock, operation))
    objects = []
    for name in spec["sources"]:
        if Path(name).name != name or Path(name).suffix not in (".S", ".c"):
            raise ValueError("invalid runtime source path")
        source = ROOT / "runtime" / name
        obj = work / (source.stem + ".o")
        if source.suffix == ".c":
            args = ["m68k-elf-gcc", *spec["compiler"]["cflags"], "-c", "-o", obj, source]
        else:
            args = ["m68k-elf-as", "-march=cfv4e", "-I", ROOT / "runtime", "-o", obj, source]
        command(args, cwd=work)
        objects.append(obj)
    linker = ["m68k-elf-ld", "-T", ROOT / "runtime/link.ld"]
    elf, raw = work / "runtime.elf", work / "runtime.bin"
    command([*linker, "--defsym", "GK_PACKED_RUNTIME_HASH=0", "-o", elf, *objects], cwd=work)
    command(["m68k-elf-objcopy", "-O", "binary", "-j", ".runtime", elf, raw], cwd=work)
    runtime = raw.read_bytes()
    verify(runtime, spec["append"]["runtime"]["raw"], "rebuilt Octakit runtime")
    for operation in spec["append"]["runtime"]["stock_operations"]:
        start = operation["target_offset"]
        if runtime[start:start + operation["target_length"]] != extract_stock(stock, operation):
            raise ValueError("runtime stock reconstruction differs")
    packed_path = work / "packed.bin"
    command([native, "pack", raw, packed_path], cwd=work)
    packed = b"GKA3" + len(runtime).to_bytes(4, "big") + packed_path.read_bytes()
    verify(packed, spec["append"]["runtime"]["packed"], "packed runtime")
    packed_path.write_bytes(packed)
    packed_object = work / "packed.o"
    command(["m68k-elf-objcopy", "-I", "binary", "-O", "elf32-m68k", "-B", "m68k",
             "--rename-section", ".data=.stage.packed,alloc,load,readonly,data,contents", packed_path, packed_object], cwd=work)
    rolling = 0
    for byte in packed:
        rolling = (rolling * 33 + byte) & 0xffffffff
    command([*linker, "--defsym", f"GK_PACKED_RUNTIME_HASH={rolling}", "-o", elf, *objects, packed_object], cwd=work)
    append_path = work / "append.bin"
    command(["m68k-elf-objcopy", "-O", "binary", "-j", ".early", "-j", ".stage", elf, append_path], cwd=work)
    append = append_path.read_bytes()
    verify(append, {"size": spec["append"]["length"], "sha256": spec["append"]["sha256"]}, "rebuilt append")
    image = patched + append
    verify(image, spec["output"]["os"], "combined Octakit OS")
    recipe, payload = make_recipe(spec, runtime, append)
    generated = work / "generated"
    generated.mkdir(exist_ok=True)
    (generated / "firmware.rs").write_bytes(render_rust(recipe))
    (generated / "public-bytes.dat").write_bytes(payload)
    env["OCTAKIT_GENERATED_DIR"] = str(generated)
    command([*cargo, "--features", "embedded-recipe"], cwd=work, env=env)
    firmware = out / spec["build"]["filename"]
    report = json.loads(command([native, "build", stock_syx, firmware], cwd=work))
    verify(firmware.read_bytes(), spec["output"]["sysex"], "built SysEx")
    card = firmware.with_suffix(".bin")
    command([native, "card", firmware, card], cwd=work)
    report["card_update"] = {"filename": card.name, **identity(card.read_bytes()),
                             "container_round_trip": True}
    (out / "octakit.os.bin").write_bytes(image)
    symbols = {}
    for line in command(["m68k-elf-nm", "--defined-only", elf], cwd=work).splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[2].startswith(("gk_", "__gk_")):
            symbols[fields[2]] = int(fields[0], 16)
    plan = {"interface_version": 1, "id": spec["id"], "source": spec["source"]["os"],
            "output": spec["output"]["os"], "image": "octakit.os.bin", "load_address": 0x40000400,
            "patches": [{k: p[k] for k in ("name", "offset", "length", "sha256")} for p in spec["patches"]],
            "append": {k: spec["append"][k] for k in ("offset", "length", "sha256")},
            "memory": spec["memory"], "symbols": symbols}
    (out / "plan.json").write_text(json.dumps(plan, indent=2) + "\n")
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    if web:
        from web_build import build_web
        build_web(ROOT, work, out, cargo, env, recipe, payload, stock)
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stock", type=Path, required=True, help="official OS 1.40C ZIP or SysEx")
    parser.add_argument("--out", type=Path, required=True, help="local build output directory")
    parser.add_argument("--web", action="store_true", help="also build browser assets")
    args = parser.parse_args()
    try:
        report = build(args.stock, args.out, args.web)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"{error}\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
