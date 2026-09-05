#!/usr/bin/env python3
"""Audit every byte of the public WASM and its embedded sparse payload."""

from __future__ import annotations

import base64
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path


WASM_MAGIC = b"\x00asm\x01\x00\x00\x00"
MATCH_MINIMUM = 16
REVIEW_SCHEMA_VERSION = 2
REVIEW_COORDINATE_SYSTEM = "payload-exterior-module-edge-distance-v1"
BEFORE_PAYLOAD = "before-payload"
AFTER_PAYLOAD = "after-payload"
REVIEW_LOCATION_SIDES = {BEFORE_PAYLOAD, AFTER_PAYLOAD}
REVIEW_LOCATION_ORDER = {BEFORE_PAYLOAD: 0, AFTER_PAYLOAD: 1}
REVIEW_LOCATION_ANCHORS = {
    BEFORE_PAYLOAD: "module-start",
    AFTER_PAYLOAD: "module-end",
}
DEV_FILENAME = re.compile(rb"ot-[0-9]{2}[1-9ABC][0-9]{2}-[0-9]{6}-dev\.syx")
PRIVATE_FILENAME = re.compile(
    rb"ot-[0-9]{2}[1-9ABC][0-9]{2}-[0-9]{6}-(?:beta|release)\.syx"
)
POSIX_HOME_PATH = re.compile(rb"/(?:Users|home)/[^/\x00]{1,128}/")
WINDOWS_HOME_PATH = re.compile(rb"[A-Za-z]:\\Users\\[^\\\x00]{1,128}\\")
FORBIDDEN_MARKERS = (
    b"expected_bytes",
    b"original_bytes",
    b"guard_bytes",
    b"stock_bytes",
    b"embedded.otrecipe",
    b"embedded.otpayload",
    b"global-kit-experimental-checkpoint",
)
ALLOWED_PAYLOAD_PROVENANCE = {
    "project-authored-source",
    "generic-tooling",
    "minimal-functional-hook-metadata-opcodes",
}
FORBIDDEN_STATIC_SUFFIXES = {
    ".otpatch",
    ".otrecipe",
    ".otpayload",
    ".syx",
    ".bin",
    ".map",
    ".d.ts",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_uleb128(data: bytes, offset: int, end: int) -> tuple[int, int]:
    value = 0
    for shift in range(0, 70, 7):
        if offset >= end:
            raise ValueError("truncated WebAssembly LEB128 value")
        byte = data[offset]
        offset += 1
        value |= (byte & 0x7F) << shift
        if byte & 0x80 == 0:
            return value, offset
    raise ValueError("oversized WebAssembly LEB128 value")


def custom_section_names(data: bytes) -> list[str]:
    if not data.startswith(WASM_MAGIC):
        raise ValueError("file is not a WebAssembly 1 module")
    names: list[str] = []
    offset = len(WASM_MAGIC)
    while offset < len(data):
        section_id = data[offset]
        size, payload_offset = read_uleb128(data, offset + 1, len(data))
        section_end = payload_offset + size
        if section_end > len(data):
            raise ValueError("WebAssembly section extends past the module")
        if section_id == 0:
            name_size, name_offset = read_uleb128(data, payload_offset, section_end)
            name_end = name_offset + name_size
            if name_end > section_end:
                raise ValueError("WebAssembly custom-section name is truncated")
            try:
                names.append(data[name_offset:name_end].decode("utf-8"))
            except UnicodeDecodeError as error:
                raise ValueError("WebAssembly custom-section name is not UTF-8") from error
        offset = section_end
    return names


def _public_payload(recipe: dict[str, object]) -> tuple[bytes, list[dict[str, object]]]:
    record = recipe.get("public_payload")
    provenance = recipe.get("provenance")
    if not isinstance(record, dict) or not isinstance(provenance, dict):
        raise ValueError("recipe lacks public payload provenance")
    encoded = record.get("data")
    if record.get("encoding") != "base64" or not isinstance(encoded, str):
        raise ValueError("recipe public payload encoding differs")
    try:
        payload = base64.b64decode(encoded, validate=True)
    except ValueError as error:
        raise ValueError("recipe public payload is not canonical base64") from error
    if base64.b64encode(payload).decode("ascii") != encoded:
        raise ValueError("recipe public payload is not canonical base64")
    if len(payload) != record.get("size") or sha256(payload) != record.get("sha256"):
        raise ValueError("recipe public payload identity differs")
    ledger = provenance.get("public_payload_ledger")
    if not isinstance(ledger, list):
        raise ValueError("recipe lacks public payload byte ledger")
    cursor = 0
    rows: list[dict[str, object]] = []
    for index, value in enumerate(ledger):
        if not isinstance(value, dict):
            raise ValueError(f"payload ledger row {index} is invalid")
        offset = value.get("payload_offset")
        length = value.get("length")
        category = value.get("provenance")
        if offset != cursor or not isinstance(length, int) or length <= 0:
            raise ValueError("payload ledger is not exact and contiguous")
        if category not in ALLOWED_PAYLOAD_PROVENANCE:
            raise ValueError(f"payload ledger contains forbidden provenance: {category}")
        cursor += length
        rows.append(value)
    if cursor != len(payload):
        raise ValueError("payload ledger does not classify every public byte")
    return payload, rows


def significant_matches(
    target: bytes,
    stock: bytes,
    minimum: int = MATCH_MINIMUM,
) -> list[tuple[int, int, int]]:
    """Scan every target offset for exact stock matches.

    Uniform-byte runs are consolidated to their maximal target ranges.  This
    keeps zero-filled compiler tables reviewable without hiding them or
    recording every overlapping suffix of the same run.
    """
    if len(target) < minimum or len(stock) < minimum:
        return []

    uniform_matches: list[tuple[int, int, int]] = []
    stock_uniform: dict[int, tuple[int, int]] = {}
    source_offset = 0
    while source_offset < len(stock):
        source_end = source_offset + 1
        while source_end < len(stock) and stock[source_end] == stock[source_offset]:
            source_end += 1
        length = source_end - source_offset
        byte = stock[source_offset]
        if length >= minimum and length > stock_uniform.get(byte, (0, 0))[1]:
            stock_uniform[byte] = (source_offset, length)
        source_offset = source_end

    target_offset = 0
    while target_offset < len(target):
        target_end = target_offset + 1
        while target_end < len(target) and target[target_end] == target[target_offset]:
            target_end += 1
        target_length = target_end - target_offset
        source = stock_uniform.get(target[target_offset])
        if target_length >= minimum and source is not None:
            uniform_matches.append(
                (target_offset, source[0], min(target_length, source[1]))
            )
        target_offset = target_end

    stock_windows: dict[bytes, int] = {}
    for source_offset in range(len(stock) - minimum + 1):
        stock_windows.setdefault(
            stock[source_offset:source_offset + minimum], source_offset
        )
    matches: list[tuple[int, int, int]] = []
    for target_offset in range(len(target) - minimum + 1):
        window = target[target_offset:target_offset + minimum]
        first_source = stock_windows.get(window)
        if first_source is None or len(set(window)) == 1:
            continue
        best_source = first_source
        best_length = minimum
        source_offset = first_source
        while source_offset >= 0:
            length = minimum
            while (
                target_offset + length < len(target)
                and source_offset + length < len(stock)
                and target[target_offset + length] == stock[source_offset + length]
            ):
                length += 1
            if length > best_length:
                best_source = source_offset
                best_length = length
            source_offset = stock.find(window, source_offset + 1)
        matches.append((target_offset, best_source, best_length))
    # Every target offset was inspected above.  Drop only ranges wholly
    # contained in an earlier, longer exact match so the manual review ledger
    # is complete without recording redundant suffixes.
    maximal: list[tuple[int, int, int]] = []
    covered_end = -1
    for match in sorted(
        uniform_matches + matches,
        key=lambda row: (row[0], -row[2], row[1]),
    ):
        target_offset, _source_offset, length = match
        if target_offset + length <= covered_end:
            continue
        maximal.append(match)
        covered_end = max(covered_end, target_offset + length)
    return maximal


def _review_key(data: bytes, source_offset: int) -> tuple[str, int, int]:
    return sha256(data), len(data), source_offset


def _canonical_locations(
    locations: list[tuple[str, int]] | tuple[tuple[str, int], ...],
) -> tuple[tuple[str, int], ...]:
    return tuple(
        sorted(
            locations,
            key=lambda value: (REVIEW_LOCATION_ORDER[value[0]], value[1]),
        )
    )


def _payload_exterior_location(
    target_offset: int,
    length: int,
    *,
    payload_offset: int,
    payload_end: int,
    module_size: int,
) -> tuple[str, int]:
    """Pin one non-payload match to its stable exterior module edge."""
    target_end = target_offset + length
    if (
        target_offset < 0
        or length <= 0
        or payload_offset < 0
        or payload_end < payload_offset
        or module_size < payload_end
        or target_end > module_size
    ):
        raise ValueError("reviewed WebAssembly match geometry is invalid")
    if target_end <= payload_offset:
        return BEFORE_PAYLOAD, target_offset
    if target_offset >= payload_end:
        return AFTER_PAYLOAD, module_size - target_end
    raise ValueError("reviewed WebAssembly match intersects the public payload")


def _location_record(location: tuple[str, int]) -> dict[str, object]:
    return {
        "side": location[0],
        "anchor": REVIEW_LOCATION_ANCHORS[location[0]],
        "distance": location[1],
    }


def _load_reviews(
    path: Path,
) -> dict[
    tuple[str, int, int],
    tuple[tuple[tuple[str, int], ...], str, str],
]:
    try:
        root = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"could not read WASM match reviews: {error}") from error
    if not isinstance(root, dict) or set(root) != {
        "schema_version",
        "minimum_match_length",
        "target_coordinate_system",
        "reviews",
    }:
        raise ValueError("WASM match review document fields differ")
    if root.get("schema_version") != REVIEW_SCHEMA_VERSION:
        raise ValueError("WASM match review schema differs")
    if root.get("minimum_match_length") != MATCH_MINIMUM:
        raise ValueError("WASM match review threshold differs")
    if root.get("target_coordinate_system") != REVIEW_COORDINATE_SYSTEM:
        raise ValueError("WASM match review coordinate system differs")
    records = root.get("reviews")
    if not isinstance(records, list):
        raise ValueError("WASM match reviews must be an array")
    reviews: dict[
        tuple[str, int, int],
        tuple[tuple[tuple[str, int], ...], str, str],
    ] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict) or set(record) != {
            "sha256",
            "length",
            "source_offset",
            "count",
            "target_locations",
            "classification",
            "reason",
        }:
            raise ValueError(f"WASM match review {index} is invalid")
        key = (record.get("sha256"), record.get("length"), record.get("source_offset"))
        if (
            not isinstance(key[0], str)
            or re.fullmatch(r"[0-9a-f]{64}", key[0]) is None
            or not isinstance(key[1], int)
            or isinstance(key[1], bool)
            or key[1] < MATCH_MINIMUM
            or not isinstance(key[2], int)
            or isinstance(key[2], bool)
            or key[2] < 0
        ):
            raise ValueError(f"WASM match review {index} identity is invalid")
        count = record.get("count")
        target_records = record.get("target_locations")
        classification = record.get("classification")
        reason = record.get("reason")
        locations: list[tuple[str, int]] = []
        if isinstance(target_records, list):
            for location in target_records:
                if not isinstance(location, dict) or set(location) != {
                    "side",
                    "anchor",
                    "distance",
                }:
                    raise ValueError(
                        f"WASM match review {index} location is invalid"
                    )
                side = location.get("side")
                anchor = location.get("anchor")
                distance = location.get("distance")
                if (
                    not isinstance(side, str)
                    or side not in REVIEW_LOCATION_SIDES
                    or anchor != REVIEW_LOCATION_ANCHORS[side]
                    or not isinstance(distance, int)
                    or isinstance(distance, bool)
                    or distance < 0
                ):
                    raise ValueError(
                        f"WASM match review {index} location is invalid"
                    )
                locations.append((str(side), distance))
        canonical_locations = _canonical_locations(locations)
        if (
            not isinstance(count, int)
            or isinstance(count, bool)
            or count <= 0
            or not isinstance(target_records, list)
            or len(locations) != count
            or tuple(locations) != canonical_locations
            or len(set(locations)) != len(locations)
            or classification not in {
                "generic-tooling-coincidence",
                "minimal-functional-metadata-coincidence",
                "project-source-coincidence",
            }
            or not isinstance(reason, str)
            or not reason
        ):
            raise ValueError(f"WASM match review {index} disposition is invalid")
        if key in reviews:
            raise ValueError("duplicate WASM match review")
        reviews[key] = (canonical_locations, classification, reason)
    return reviews


def audit_static_assets(static_root: Path) -> None:
    forbidden = sorted(
        path
        for path in static_root.rglob("*")
        if path.is_file() and path.suffix.lower() in FORBIDDEN_STATIC_SUFFIXES
    )
    if forbidden:
        raise ValueError(
            "forbidden firmware/recipe/source-map static assets: "
            + ", ".join(str(path) for path in forbidden)
        )


def audit_public_wasm(
    data: bytes,
    *,
    stock_os: bytes,
    recipe: dict[str, object],
    reviews: dict[
        tuple[str, int, int],
        tuple[tuple[tuple[str, int], ...], str, str],
    ],
) -> tuple[str, list[dict[str, object]], list[dict[str, object]]]:
    if recipe.get("schema_version") != 3:
        raise ValueError("public WASM audit requires sparse recipe schema 3")
    source = recipe.get("source")
    if not isinstance(source, dict) or not isinstance(source.get("os"), dict):
        raise ValueError("recipe lacks authenticated stock OS identity")
    stock_identity = source["os"]
    if (
        stock_identity.get("size") != len(stock_os)
        or stock_identity.get("sha256") != sha256(stock_os)
    ):
        raise ValueError("WASM audit stock OS differs from recipe identity")

    custom_names = custom_section_names(data)
    forbidden_custom = sorted({"name", "producers"}.intersection(custom_names))
    if forbidden_custom:
        raise ValueError("public WebAssembly retains debug metadata: " + ", ".join(forbidden_custom))

    private_name = PRIVATE_FILENAME.search(data)
    if private_name is not None:
        raise ValueError(
            "public WebAssembly exposes a private output filename: "
            + private_name.group().decode("ascii")
        )
    dev_names = {match.group().decode("ascii") for match in DEV_FILENAME.finditer(data)}
    if len(dev_names) != 1:
        raise ValueError("public WebAssembly must expose exactly one development filename")
    for pattern in (POSIX_HOME_PATH, WINDOWS_HOME_PATH):
        leaked_path = pattern.search(data)
        if leaked_path is not None:
            raise ValueError(
                "public WebAssembly exposes a local home-directory path: "
                + leaked_path.group().decode("utf-8", errors="replace")
            )
    for marker in FORBIDDEN_MARKERS:
        if marker in data:
            raise ValueError(
                "public WebAssembly exposes forbidden build/source metadata: "
                + marker.decode("ascii")
            )

    payload, payload_ledger = _public_payload(recipe)
    payload_offset = data.find(payload)
    if payload_offset < 0 or data.find(payload, payload_offset + 1) >= 0:
        raise ValueError("public payload must occur exactly once in WebAssembly")

    byte_map: list[dict[str, object]] = []
    if payload_offset:
        byte_map.append(
            {
                "wasm_offset": 0,
                "length": payload_offset,
                "provenance": "generic-tooling",
                "source": "WebAssembly/Rust compiler output from project sources, generated numeric metadata, and generic dependencies",
                "source_components": [
                    "src/lib.rs",
                    "generated/firmware.rs",
                    "Rust core/alloc and declared Cargo dependencies",
                    "rustc/LLVM and wasm-bindgen container encoding",
                ],
            }
        )
    for row in payload_ledger:
        byte_map.append(
            {
                "wasm_offset": payload_offset + int(row["payload_offset"]),
                "length": row["length"],
                "provenance": row["provenance"],
                "source": row["source"],
            }
        )
    payload_end = payload_offset + len(payload)
    if payload_end < len(data):
        byte_map.append(
            {
                "wasm_offset": payload_end,
                "length": len(data) - payload_end,
                "provenance": "generic-tooling",
                "source": "WebAssembly/Rust compiler output from project sources, generated numeric metadata, and generic dependencies",
                "source_components": [
                    "src/lib.rs",
                    "generated/firmware.rs",
                    "Rust core/alloc and declared Cargo dependencies",
                    "rustc/LLVM and wasm-bindgen container encoding",
                ],
            }
        )
    if sum(int(row["length"]) for row in byte_map) != len(data):
        raise ValueError("public WASM provenance map does not cover every byte")

    matches = significant_matches(data, stock_os)
    grouped: dict[tuple[str, int, int], list[int]] = defaultdict(list)
    for target_offset, source_offset, length in matches:
        if target_offset < payload_end and target_offset + length > payload_offset:
            raise ValueError(
                "embedded public payload has a significant exact stock match: "
                f"WASM +0x{target_offset:x}, stock +0x{source_offset:x}, "
                f"{length} bytes"
            )
        matched = data[target_offset:target_offset + length]
        grouped[_review_key(matched, source_offset)].append(target_offset)
    actual_locations = {
        key: _canonical_locations(
            [
                _payload_exterior_location(
                    target_offset,
                    key[1],
                    payload_offset=payload_offset,
                    payload_end=payload_end,
                    module_size=len(data),
                )
                for target_offset in offsets
            ]
        )
        for key, offsets in grouped.items()
    }
    expected_locations = {key: value[0] for key, value in reviews.items()}
    if actual_locations != expected_locations:
        lines = ["whole-WASM stock match review differs:"]
        for key in sorted(set(actual_locations) | set(expected_locations)):
            actual = actual_locations.get(key, ())
            expected = expected_locations.get(key, ())
            if actual == expected:
                continue
            digest, length, source_offset = key
            lines.append(
                f"  sha256={digest} length={length} source_offset={source_offset} "
                f"actual_target_locations="
                f"{[_location_record(value) for value in actual[:12]]} "
                f"expected_target_locations="
                f"{[_location_record(value) for value in expected[:12]]} "
                f"actual_absolute_offsets={grouped.get(key, [])[:12]}"
            )
        raise ValueError("\n".join(lines))
    match_report = [
        {
            "sha256": key[0],
            "length": key[1],
            "source_offset": key[2],
            "count": len(offsets),
            "target_offsets": offsets,
            "target_locations": [
                _location_record(value) for value in actual_locations[key]
            ],
            "classification": reviews[key][1],
            "reason": reviews[key][2],
        }
        for key, offsets in sorted(grouped.items())
    ]
    return next(iter(dev_names)), byte_map, match_report
