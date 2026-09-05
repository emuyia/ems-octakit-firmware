import json


def rust_string(value: object, label: str) -> str:
    if not isinstance(value, str):
        raise ValueError(f"{label} must be a string")
    try:
        value.encode("ascii")
    except UnicodeEncodeError as error:
        raise ValueError(f"{label} must be ASCII") from error
    return json.dumps(value)

def rust_identity(value: object, label: str) -> str:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    size = value.get("size")
    if not isinstance(size, int) or isinstance(size, bool) or size < 0:
        raise ValueError(f"{label}.size must be a non-negative integer")
    digest = rust_string(value.get("sha256"), f"{label}.sha256")
    return f"Identity {{ size: {size}, sha256: {digest}.into() }}"

def render_rust(document: dict[str, object]) -> bytes:
    source = document["source"]
    build = document["build"]
    format_record = document["format"]
    append = document["append"]
    payload = document["public_payload"]
    provenance = document["provenance"]
    output = document["output"]
    for label, value in (
        ("source", source),
        ("build", build),
        ("format", format_record),
        ("append", append),
        ("public_payload", payload),
        ("provenance", provenance),
        ("output", output),
    ):
        if not isinstance(value, dict):
            raise ValueError(f"{label} must be an object")

    distributions = source["distributions"]
    if not isinstance(distributions, list):
        raise ValueError("source.distributions must be an array")
    distribution_rows = []
    for distribution in distributions:
        distribution_rows.append(
            "DistributionIdentity { "
            f"name: {rust_string(distribution['name'], 'distribution.name')}.into(), "
            f"size: {distribution['size']}, "
            f"sha256: {rust_string(distribution['sha256'], 'distribution.sha256')}.into() "
            "}"
        )

    operation_rows = [
        "WriteSpec { "
        f"offset: {operation['offset']}, length: {operation['length']}, "
        f"payload_offset: {operation['payload_offset']} "
        "}"
        for operation in document["operations"]
    ]
    runtime = append["runtime"]
    public_range_rows = [
        "RuntimePublicRange { "
        f"target_offset: {row['target_offset']}, length: {row['length']}, "
        f"payload_offset: {row['payload_offset']} "
        "}"
        for row in runtime["public_ranges"]
    ]
    stock_operation_rows = []
    for operation in runtime["stock_operations"]:
        kind = 0 if operation["kind"] == "stock-copy" else 1
        policy = {
            "exact-copy": 0,
            "preserve-encoding": 1,
            "preserve-absolute-control-flow": 2,
        }[operation["policy"]]
        layout = operation.get("instruction_lengths", [])
        stock_operation_rows.append(
            "StockOperation { "
            f"kind: {kind}, policy: {policy}, "
            f"source_offset: {operation['source_offset']}, "
            f"target_offset: {operation['target_offset']}, "
            f"source_length: {operation['source_length']}, "
            f"target_length: {operation['target_length']}, "
            f"instruction_lengths: vec![{', '.join(str(value) for value in layout)}] "
            "}"
        )

    loader = append["loader"]
    stage = append["stage_header"]
    lines = [
        "// Generated locally by build.py.",
        "const EMBEDDED_PUBLIC_BYTES: &[u8] =",
        "    include_bytes!(\"public-bytes.dat\");",
        "",
        "#[rustfmt::skip]",
        "fn generated_recipe() -> BuildRecipe {",
        "    BuildRecipe {",
        f"        schema_version: {document['schema_version']},",
        f"        kind: {rust_string(document['kind'], 'kind')}.into(),",
        f"        id: {rust_string(document['id'], 'id')}.into(),",
        "        source: SourceSpec {",
        f"            product: {rust_string(source['product'], 'source.product')}.into(),",
        f"            version: {rust_string(source['version'], 'source.version')}.into(),",
        f"            distributions: vec![{', '.join(distribution_rows)}],",
        f"            sysex: {rust_identity(source['sysex'], 'source.sysex')},",
        f"            container: {rust_identity(source['container'], 'source.container')},",
        f"            packed: {rust_identity(source['packed'], 'source.packed')},",
        f"            os: {rust_identity(source['os'], 'source.os')},",
        "        },",
        "        build: BuildSpec {",
        f"            version: {rust_string(build['version'], 'build.version')}.into(),",
        f"            stamp: {rust_string(build['stamp'], 'build.stamp')}.into(),",
        f"            prefix: {rust_string(build['prefix'], 'build.prefix')}.into(),",
        f"            output_filename: {rust_string(build['filename'], 'development filename')}.into(),",
        f"            max_candidates: {build['max_candidates']},",
        f"            max_container_size: {build['max_container_size']},",
        "        },",
        "        format: FormatSpec {",
        f"            os_load_address: {format_record['os_load_address']},",
        f"            operations: {rust_string(format_record['operations'], 'format.operations')}.into(),",
        "        },",
        f"        operations: vec![{', '.join(operation_rows)}],",
        "        append: AppendSpec {",
        f"            offset: {append['offset']}, length: {append['length']},",
        f"            sha256: {rust_string(append['sha256'], 'append.sha256')}.into(),",
        "            loader: PublicBlobSpec {",
        f"                target_offset: {loader['target_offset']}, length: {loader['length']}, payload_offset: {loader['payload_offset']},",
        f"                identity: {rust_identity(loader, 'append.loader')},",
        "            },",
        "            stage_header: PublicBlobSpec {",
        f"                target_offset: {stage['target_offset']}, length: {stage['length']}, payload_offset: {stage['payload_offset']},",
        f"                identity: {rust_identity(stage, 'append.stage_header')},",
        "            },",
        "            runtime: RuntimeSpec {",
        f"                target_offset: {runtime['target_offset']}, load_address: {runtime['load_address']},",
        f"                raw: {rust_identity(runtime['raw'], 'append.runtime.raw')},",
        f"                packed: {rust_identity(runtime['packed'], 'append.runtime.packed')},",
        f"                public_ranges: vec![{', '.join(public_range_rows)}],",
        f"                stock_operations: vec![{', '.join(stock_operation_rows)}],",
        "            },",
        "        },",
        "        public_payload: PublicPayloadSpec {",
        f"            size: {payload['size']},",
        f"            sha256: {rust_string(payload['sha256'], 'public_payload.sha256')}.into(),",
        f"            replacement_bytes: {payload['replacement_bytes']},",
        "            data: EMBEDDED_PUBLIC_BYTES.to_vec(),",
        "        },",
        "        provenance: ProvenanceSpec {",
        f"            guard_or_original_byte_arrays_embedded: {str(provenance['guard_or_original_byte_arrays_embedded']).lower()},",
        f"            stock_derived_payload_blobs_embedded: {str(provenance['stock_derived_payload_blobs_embedded']).lower()},",
        f"            replacement_encoding: {rust_string(provenance['replacement_encoding'], 'replacement encoding')}.into(),",
        f"            unchanged_source_bytes_in_replacements: {provenance['unchanged_source_bytes_in_replacements']},",
        f"            omitted_unchanged_source_bytes: {provenance['omitted_unchanged_source_bytes']},",
        f"            append_origin: {rust_string(provenance['append_origin'], 'append origin')}.into(),",
        f"            stock_derived_expression_ranges: {provenance['stock_derived_expression_ranges']},",
        "        },",
        "        output: OutputSpec {",
        f"            os: {rust_identity(output['os'], 'output.os')},",
        f"            packed: {rust_identity(output['packed'], 'output.packed')},",
        f"            container: {rust_identity(output['container'], 'output.container')},",
        f"            sysex: {rust_identity(output['sysex'], 'output.sysex')},",
        "        },",
        "    }",
        "}",
        "",
    ]
    return "\n".join(lines).encode("utf-8")
