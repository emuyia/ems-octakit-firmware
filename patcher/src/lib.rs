#![cfg_attr(not(feature = "embedded-recipe"), allow(dead_code))]

use serde::Serialize;
use sha2::{Digest, Sha256};
use wasm_bindgen::prelude::*;

const SCHEMA_VERSION: u32 = 3;
const RECIPE_KIND: &str = "octatrack-local-build-recipe";
const OPERATION_ENCODING: &str = "sparse-public-write-v3";
const APPEND_ORIGIN: &str = "authenticated-stock-local-reconstruction-v1";
const OS_LOAD_ADDRESS: usize = 0x4000_0400;
const RUNTIME_LOAD_ADDRESS: usize = 0x45d0_dde0;
const PACKED_RUNTIME_MAGIC: &[u8; 4] = b"GKA3";
const CONTAINER_HEADER_SIZE: usize = 26;
const PACKET_DECODED_SIZE: usize = 63;
const START_OFFSET: usize = 0x004000;
const MANUFACTURER: [u8; 3] = [0x00, 0x20, 0x3c];
const PRODUCT: u8 = 0x05;
const SUBPRODUCT: u8 = 0x00;
const DATA_CMD: u8 = 0x7e;
const FINAL_CMD: u8 = 0x7f;
const MAX_OFFSET_FOR_LEN2: usize = 0x0d00;
const MAX_MATCH_LEN: usize = 0x8000;
const HASH3_BITS: usize = 20;
const HASH3_SIZE: usize = 1 << HASH3_BITS;
const HASH3_MASK: u32 = (HASH3_SIZE - 1) as u32;
const HASH2_SIZE: usize = 1 << 16;

#[derive(Debug, Serialize)]
struct Identity {
    size: usize,
    sha256: String,
}

#[derive(Debug, Serialize)]
struct DistributionIdentity {
    name: String,
    size: usize,
    sha256: String,
}

#[derive(Debug)]
struct SourceSpec {
    product: String,
    version: String,
    distributions: Vec<DistributionIdentity>,
    sysex: Identity,
    container: Identity,
    packed: Identity,
    os: Identity,
}

#[derive(Debug)]
struct BuildSpec {
    version: String,
    stamp: String,
    prefix: String,
    output_filename: String,
    max_candidates: usize,
    max_container_size: usize,
}

#[derive(Debug)]
struct FormatSpec {
    os_load_address: usize,
    operations: String,
}

#[derive(Debug)]
struct WriteSpec {
    offset: usize,
    length: usize,
    payload_offset: usize,
}

#[derive(Debug)]
struct PublicBlobSpec {
    target_offset: usize,
    length: usize,
    payload_offset: usize,
    identity: Identity,
}

#[derive(Debug)]
struct RuntimePublicRange {
    target_offset: usize,
    length: usize,
    payload_offset: usize,
}

#[derive(Debug)]
struct StockOperation {
    // 0 = exact stock copy, 1 = M68k relocation.
    kind: u8,
    // 0 = exact copy, 1 = preserve encoding, 2 = preserve absolute control flow.
    policy: u8,
    source_offset: usize,
    target_offset: usize,
    source_length: usize,
    target_length: usize,
    instruction_lengths: Vec<usize>,
}

#[derive(Debug)]
struct RuntimeSpec {
    target_offset: usize,
    load_address: usize,
    raw: Identity,
    packed: Identity,
    public_ranges: Vec<RuntimePublicRange>,
    stock_operations: Vec<StockOperation>,
}

#[derive(Debug)]
struct AppendSpec {
    offset: usize,
    length: usize,
    sha256: String,
    loader: PublicBlobSpec,
    stage_header: PublicBlobSpec,
    runtime: RuntimeSpec,
}

#[derive(Debug)]
struct PublicPayloadSpec {
    size: usize,
    sha256: String,
    replacement_bytes: usize,
    data: Vec<u8>,
}

#[derive(Debug)]
struct ProvenanceSpec {
    guard_or_original_byte_arrays_embedded: bool,
    stock_derived_payload_blobs_embedded: bool,
    replacement_encoding: String,
    unchanged_source_bytes_in_replacements: usize,
    omitted_unchanged_source_bytes: usize,
    append_origin: String,
    stock_derived_expression_ranges: usize,
}

#[derive(Debug, Serialize)]
struct OutputSpec {
    os: Identity,
    packed: Identity,
    container: Identity,
    sysex: Identity,
}

#[derive(Debug)]
struct BuildRecipe {
    schema_version: u32,
    kind: String,
    id: String,
    source: SourceSpec,
    build: BuildSpec,
    format: FormatSpec,
    operations: Vec<WriteSpec>,
    append: AppendSpec,
    public_payload: PublicPayloadSpec,
    provenance: ProvenanceSpec,
    output: OutputSpec,
}

#[cfg(feature = "embedded-recipe")]
include!(concat!(env!("OUT_DIR"), "/firmware.rs"));

#[derive(Debug)]
struct Container<'a> {
    product: String,
    version: String,
    packed: &'a [u8],
}

#[derive(Serialize)]
struct BuildReport<'a> {
    recipe_id: &'a str,
    source_product: &'a str,
    source_version: &'a str,
    output_version: &'a str,
    output_size: usize,
    output_sha256: String,
    filename: &'a str,
    verification: VerificationReport,
}

#[derive(Serialize)]
struct VerificationReport {
    stock_sysex: bool,
    stock_container: bool,
    stock_os: bool,
    public_payload: bool,
    target_os: bool,
    packed_stream: bool,
    output_container: bool,
    output_sysex: bool,
    output_round_trip: bool,
}

#[derive(Serialize)]
struct BrowserRecipeSource<'a> {
    distributions: &'a [DistributionIdentity],
    sysex: &'a Identity,
}

#[derive(Serialize)]
struct BrowserRecipeBuild<'a> {
    filename: &'a str,
}

#[derive(Serialize)]
struct BrowserRecipeMetadata<'a> {
    id: &'a str,
    source: BrowserRecipeSource<'a>,
    build: BrowserRecipeBuild<'a>,
    output: &'a OutputSpec,
}

#[wasm_bindgen]
pub struct BuildArtifact {
    sysex: Vec<u8>,
    report_json: String,
}

#[wasm_bindgen]
impl BuildArtifact {
    pub fn sysex(&self) -> Vec<u8> {
        self.sysex.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn report_json(&self) -> String {
        self.report_json.clone()
    }
}

#[wasm_bindgen]
pub fn patcher_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[wasm_bindgen]
pub fn validate_embedded_recipe() -> Result<(), JsValue> {
    embedded_recipe()
        .map(|_| ())
        .map_err(|error| JsValue::from_str(&error))
}

#[wasm_bindgen]
pub fn recipe_metadata() -> Result<String, JsValue> {
    let recipe = embedded_recipe().map_err(|error| JsValue::from_str(&error))?;
    let metadata = BrowserRecipeMetadata {
        id: &recipe.id,
        source: BrowserRecipeSource {
            distributions: &recipe.source.distributions,
            sysex: &recipe.source.sysex,
        },
        build: BrowserRecipeBuild {
            filename: &recipe.build.output_filename,
        },
        output: &recipe.output,
    };
    serde_json::to_string(&metadata)
        .map_err(|error| JsValue::from_str(&format!("could not encode recipe metadata: {error}")))
}

#[wasm_bindgen]
pub fn build_firmware(stock_sysex: &[u8]) -> Result<BuildArtifact, JsValue> {
    let (sysex, report_json) =
        build_firmware_bytes(stock_sysex).map_err(|error| JsValue::from_str(&error))?;
    Ok(BuildArtifact { sysex, report_json })
}

#[doc(hidden)]
pub fn build_firmware_bytes(stock_sysex: &[u8]) -> Result<(Vec<u8>, String), String> {
    let recipe = embedded_recipe()?;
    verify_identity("stock SysEx", stock_sysex, &recipe.source.sysex)?;

    let stock_container_bytes = decode_firmware(stock_sysex)?;
    verify_identity(
        "stock container",
        &stock_container_bytes,
        &recipe.source.container,
    )?;
    let stock_container = parse_container(&stock_container_bytes)?;
    if stock_container.product != recipe.source.product {
        return Err(format!(
            "stock product is {}, patch requires {}",
            stock_container.product, recipe.source.product
        ));
    }
    if stock_container.version != recipe.source.version {
        return Err(format!(
            "stock version is {}, patch requires {}",
            stock_container.version, recipe.source.version
        ));
    }
    verify_identity(
        "stock packed stream",
        stock_container.packed,
        &recipe.source.packed,
    )?;

    let stock_os = depack(stock_container.packed)?;
    verify_identity("stock OS", &stock_os, &recipe.source.os)?;

    let public_payload = validate_public_payload(&recipe.public_payload)?;
    let target_os = apply_recipe(&stock_os, &recipe, public_payload)?;
    verify_identity("built OS", &target_os, &recipe.output.os)?;

    let packed = pack(&target_os, recipe.build.max_candidates)?;
    verify_identity("rebuilt packed stream", &packed, &recipe.output.packed)?;

    let output_container = build_container(&stock_container_bytes, &packed, &recipe.build.version)?;
    if output_container.len() > recipe.build.max_container_size {
        return Err(format!(
            "rebuilt container has {} bytes, limit is {}",
            output_container.len(),
            recipe.build.max_container_size
        ));
    }
    verify_identity(
        "rebuilt container",
        &output_container,
        &recipe.output.container,
    )?;

    let output_sysex = encode_firmware(&output_container)?;
    verify_identity("rebuilt SysEx", &output_sysex, &recipe.output.sysex)?;

    let round_trip_container = decode_firmware(&output_sysex)?;
    if round_trip_container != output_container {
        return Err("generated SysEx failed its container round trip".into());
    }
    let round_trip_parsed = parse_container(&round_trip_container)?;
    let round_trip_os = depack(round_trip_parsed.packed)?;
    if round_trip_os != target_os {
        return Err("generated SysEx failed its OS round trip".into());
    }

    let report = BuildReport {
        recipe_id: &recipe.id,
        source_product: &recipe.source.product,
        source_version: &recipe.source.version,
        output_version: &recipe.build.version,
        output_size: output_sysex.len(),
        output_sha256: sha256_hex(&output_sysex),
        filename: &recipe.build.output_filename,
        verification: VerificationReport {
            stock_sysex: true,
            stock_container: true,
            stock_os: true,
            public_payload: true,
            target_os: true,
            packed_stream: true,
            output_container: true,
            output_sysex: true,
            output_round_trip: true,
        },
    };
    let report_json = serde_json::to_string(&report)
        .map_err(|error| format!("could not encode build report: {error}"))?;
    Ok((output_sysex, report_json))
}

#[cfg(feature = "embedded-recipe")]
fn embedded_recipe() -> Result<BuildRecipe, String> {
    let recipe = generated_recipe();
    validate_recipe(&recipe)?;
    validate_public_payload(&recipe.public_payload)?;
    Ok(recipe)
}

#[cfg(not(feature = "embedded-recipe"))]
fn embedded_recipe() -> Result<BuildRecipe, String> {
    Err("this build has no embedded local-build recipe".into())
}

fn valid_stamp(stamp: &str) -> bool {
    let bytes = stamp.as_bytes();
    bytes.len() == 12
        && bytes[..2].iter().all(u8::is_ascii_digit)
        && matches!(bytes[2], b'1'..=b'9' | b'A' | b'B' | b'C')
        && bytes[3..5].iter().all(u8::is_ascii_digit)
        && bytes[5] == b'-'
        && bytes[6..].iter().all(u8::is_ascii_digit)
}

fn validate_recipe(recipe: &BuildRecipe) -> Result<(), String> {
    if recipe.schema_version != SCHEMA_VERSION {
        return Err(format!(
            "unsupported recipe schema {}",
            recipe.schema_version
        ));
    }
    if recipe.kind != RECIPE_KIND {
        return Err(format!("unsupported recipe kind {}", recipe.kind));
    }
    if recipe.id.is_empty() {
        return Err("recipe identity must not be empty".into());
    }
    if recipe.source.product.is_empty() || recipe.source.version.is_empty() {
        return Err("source product and version must not be empty".into());
    }
    if recipe.source.distributions.is_empty() {
        return Err("source distributions must not be empty".into());
    }
    for distribution in &recipe.source.distributions {
        if distribution.name.is_empty() || distribution.size == 0 {
            return Err("source distribution identity is incomplete".into());
        }
        validate_digest("source distribution SHA-256", &distribution.sha256)?;
    }
    for (label, identity) in [
        ("source.sysex", &recipe.source.sysex),
        ("source.container", &recipe.source.container),
        ("source.packed", &recipe.source.packed),
        ("source.os", &recipe.source.os),
        ("output.os", &recipe.output.os),
        ("output.packed", &recipe.output.packed),
        ("output.container", &recipe.output.container),
        ("output.sysex", &recipe.output.sysex),
    ] {
        if identity.size == 0 {
            return Err(format!("{label}.size must be positive"));
        }
        validate_digest(&format!("{label}.sha256"), &identity.sha256)?;
    }
    if recipe.format.os_load_address != OS_LOAD_ADDRESS {
        return Err("patch OS load address differs from Octatrack".into());
    }
    if recipe.format.operations != OPERATION_ENCODING {
        return Err("unsupported recipe operation encoding".into());
    }
    if recipe.build.version.len() != 5 || !recipe.build.version.is_ascii() {
        return Err("output version must contain five ASCII bytes".into());
    }
    if !valid_stamp(&recipe.build.stamp) {
        return Err("output stamp must have form YYMDD-HHMMSS".into());
    }
    if recipe.id != format!("ot-{}", recipe.build.stamp) {
        return Err("recipe id differs from output stamp".into());
    }
    if recipe.build.prefix != "ot" {
        return Err("output prefix must be ot".into());
    }
    let expected_name = format!("ot-{}-dev.syx", recipe.build.stamp);
    if recipe.build.output_filename != expected_name {
        return Err("development output filename differs from stamp".into());
    }
    if recipe.build.max_candidates == 0 || recipe.build.max_container_size == 0 {
        return Err("build limits must be positive".into());
    }
    validate_digest("public_payload.sha256", &recipe.public_payload.sha256)?;
    validate_digest("append.sha256", &recipe.append.sha256)?;
    for (label, identity) in [
        ("append.loader", &recipe.append.loader.identity),
        ("append.stage_header", &recipe.append.stage_header.identity),
        ("append.runtime.raw", &recipe.append.runtime.raw),
        ("append.runtime.packed", &recipe.append.runtime.packed),
    ] {
        if identity.size == 0 {
            return Err(format!("{label}.size must be positive"));
        }
        validate_digest(&format!("{label}.sha256"), &identity.sha256)?;
    }

    let mut previous_end = 0usize;
    let mut replacement_bytes = 0usize;
    let mut payload_coverage = vec![false; recipe.public_payload.size];
    for (index, operation) in recipe.operations.iter().enumerate() {
        if operation.length == 0 {
            return Err(format!("recipe operation {index} is empty"));
        }
        let end = operation
            .offset
            .checked_add(operation.length)
            .ok_or_else(|| format!("recipe operation {index} overflows"))?;
        if operation.offset < previous_end {
            return Err("recipe operations are not sorted and disjoint".into());
        }
        if end > recipe.source.os.size {
            return Err(format!("recipe operation {index} exceeds the stock OS"));
        }
        mark_range(
            &mut payload_coverage,
            operation.payload_offset,
            operation.length,
            &format!("recipe operation {index} payload"),
        )?;
        replacement_bytes = replacement_bytes
            .checked_add(operation.length)
            .ok_or_else(|| "replacement byte count overflows".to_string())?;
        previous_end = end;
    }
    if replacement_bytes != recipe.public_payload.replacement_bytes {
        return Err("replacement payload length differs from operations".into());
    }

    let append = &recipe.append;
    if append.offset != recipe.source.os.size || append.length == 0 {
        return Err("append must begin at the non-empty stock OS end".into());
    }
    if append.loader.length != append.loader.identity.size
        || append.stage_header.length != append.stage_header.identity.size
    {
        return Err("public append blob length differs from identity".into());
    }
    mark_range(
        &mut payload_coverage,
        append.loader.payload_offset,
        append.loader.length,
        "loader payload",
    )?;
    mark_range(
        &mut payload_coverage,
        append.stage_header.payload_offset,
        append.stage_header.length,
        "stage-header payload",
    )?;
    if append.loader.target_offset != 0
        || append.stage_header.target_offset != append.loader.length
        || append.runtime.target_offset != append.loader.length + append.stage_header.length
    {
        return Err("append component target geometry differs".into());
    }
    if append.runtime.load_address != RUNTIME_LOAD_ADDRESS {
        return Err("runtime load address differs".into());
    }
    let mut runtime_coverage = vec![false; append.runtime.raw.size];
    for (index, range) in append.runtime.public_ranges.iter().enumerate() {
        mark_range(
            &mut runtime_coverage,
            range.target_offset,
            range.length,
            &format!("public runtime range {index}"),
        )?;
        mark_range(
            &mut payload_coverage,
            range.payload_offset,
            range.length,
            &format!("public runtime range {index} payload"),
        )?;
    }
    if append.runtime.stock_operations.is_empty() {
        return Err("runtime has no local stock reconstruction operations".into());
    }
    for (index, operation) in append.runtime.stock_operations.iter().enumerate() {
        if operation.kind > 1 || operation.policy > 2 {
            return Err(format!(
                "local stock operation {index} kind or policy is invalid"
            ));
        }
        if operation.source_length == 0 || operation.target_length == 0 {
            return Err(format!("local stock operation {index} is empty"));
        }
        let source_end = operation
            .source_offset
            .checked_add(operation.source_length)
            .ok_or_else(|| format!("local stock operation {index} source overflows"))?;
        if source_end > recipe.source.os.size {
            return Err(format!("local stock operation {index} exceeds stock OS"));
        }
        mark_range(
            &mut runtime_coverage,
            operation.target_offset,
            operation.target_length,
            &format!("local stock operation {index} target"),
        )?;
        match (operation.kind, operation.policy) {
            (0, 0) => {
                if operation.source_length != operation.target_length
                    || !operation.instruction_lengths.is_empty()
                {
                    return Err(format!("stock-copy operation {index} geometry differs"));
                }
            }
            (1, 1 | 2) => {
                if operation.instruction_lengths.is_empty()
                    || operation
                        .instruction_lengths
                        .iter()
                        .any(|length| *length == 0 || length % 2 != 0)
                    || operation.instruction_lengths.iter().sum::<usize>()
                        != operation.source_length
                {
                    return Err(format!("M68k operation {index} layout differs"));
                }
            }
            _ => return Err(format!("local stock operation {index} policy differs")),
        }
    }
    if runtime_coverage.iter().any(|covered| !covered) {
        return Err("runtime reconstruction leaves an unclassified byte".into());
    }
    if payload_coverage.iter().any(|covered| !covered) {
        return Err("public payload contains an unclassified byte".into());
    }
    let packed_runtime_size = append
        .loader
        .length
        .checked_add(append.stage_header.length)
        .and_then(|size| size.checked_add(append.runtime.packed.size))
        .ok_or_else(|| "append size overflows".to_string())?;
    if append.length != packed_runtime_size {
        return Err("append length differs from its reconstructed components".into());
    }
    let expected_output_size = recipe
        .source
        .os
        .size
        .checked_add(append.length)
        .ok_or_else(|| "output OS size overflows".to_string())?;
    if recipe.output.os.size != expected_output_size {
        return Err("output OS size differs from stock plus append".into());
    }

    if recipe.provenance.guard_or_original_byte_arrays_embedded
        || recipe.provenance.stock_derived_payload_blobs_embedded
        || recipe.provenance.stock_derived_expression_ranges != 0
    {
        return Err("recipe contains forbidden stock provenance".into());
    }
    if recipe.provenance.replacement_encoding != "changed-bytes-only"
        || recipe.provenance.unchanged_source_bytes_in_replacements != 0
    {
        return Err("recipe replacements are not changed-byte-only".into());
    }
    let _omitted_unchanged = recipe.provenance.omitted_unchanged_source_bytes;
    if recipe.provenance.append_origin != APPEND_ORIGIN {
        return Err("recipe append lacks local-stock provenance".into());
    }

    Ok(())
}

fn mark_range(
    coverage: &mut [bool],
    offset: usize,
    length: usize,
    label: &str,
) -> Result<(), String> {
    let end = offset
        .checked_add(length)
        .ok_or_else(|| format!("{label} overflows"))?;
    if length == 0 || end > coverage.len() {
        return Err(format!("{label} exceeds its buffer"));
    }
    if coverage[offset..end].iter().any(|covered| *covered) {
        return Err(format!("{label} overlaps another range"));
    }
    coverage[offset..end].fill(true);
    Ok(())
}

fn validate_digest(label: &str, digest: &str) -> Result<(), String> {
    if digest.len() != 64
        || !digest
            .bytes()
            .all(|byte| byte.is_ascii_digit() || (b'a'..=b'f').contains(&byte))
    {
        return Err(format!("{label} is not a lowercase SHA-256"));
    }
    Ok(())
}

fn sha256_hex(data: &[u8]) -> String {
    format!("{:x}", Sha256::digest(data))
}

fn verify_identity(label: &str, data: &[u8], identity: &Identity) -> Result<(), String> {
    let digest = sha256_hex(data);
    if data.len() != identity.size {
        return Err(format!(
            "{label} identity mismatch: SHA-256 {digest}, expected {}; {} bytes, expected {}",
            identity.sha256,
            data.len(),
            identity.size
        ));
    }
    if digest != identity.sha256 {
        return Err(format!(
            "{label} SHA-256 is {digest}, expected {}",
            identity.sha256
        ));
    }
    Ok(())
}

fn validate_public_payload(payload: &PublicPayloadSpec) -> Result<&[u8], String> {
    verify_identity(
        "public payload",
        &payload.data,
        &Identity {
            size: payload.size,
            sha256: payload.sha256.clone(),
        },
    )?;
    Ok(&payload.data)
}

fn apply_recipe(
    stock_os: &[u8],
    recipe: &BuildRecipe,
    public_payload: &[u8],
) -> Result<Vec<u8>, String> {
    let mut output = stock_os.to_vec();
    for (index, operation) in recipe.operations.iter().enumerate() {
        let payload_end = operation.payload_offset + operation.length;
        let replacement = &public_payload[operation.payload_offset..payload_end];
        if stock_os[operation.offset..operation.offset + operation.length]
            .iter()
            .zip(replacement)
            .any(|(source, target)| source == target)
        {
            return Err(format!(
                "recipe operation {index} contains an unchanged source byte"
            ));
        }
        output[operation.offset..operation.offset + operation.length].copy_from_slice(replacement);
    }

    let append = reconstruct_append(stock_os, recipe, public_payload)?;
    output.extend_from_slice(&append);
    Ok(output)
}

fn public_blob<'a>(
    payload: &'a [u8],
    spec: &PublicBlobSpec,
    label: &str,
) -> Result<&'a [u8], String> {
    let end = spec
        .payload_offset
        .checked_add(spec.length)
        .ok_or_else(|| format!("{label} payload range overflows"))?;
    let data = payload
        .get(spec.payload_offset..end)
        .ok_or_else(|| format!("{label} exceeds public payload"))?;
    verify_identity(label, data, &spec.identity)?;
    Ok(data)
}

fn relocate_m68k(source: &[u8], operation: &StockOperation) -> Result<Vec<u8>, String> {
    if operation.kind != 1 || !matches!(operation.policy, 1 | 2) {
        return Err("invalid M68k relocation operation".into());
    }
    if operation.instruction_lengths.iter().sum::<usize>() != source.len() {
        return Err("M68k instruction layout does not consume source".into());
    }
    let source_address = OS_LOAD_ADDRESS + operation.source_offset;
    let target_address = RUNTIME_LOAD_ADDRESS + operation.target_offset;
    let mut output = Vec::with_capacity(operation.target_length);
    let mut cursor = 0usize;
    for length in operation.instruction_lengths.iter().copied() {
        if length == 0 || length % 2 != 0 || cursor + length > source.len() {
            return Err("M68k instruction layout is invalid".into());
        }
        let instruction = &source[cursor..cursor + length];
        let opcode = u16::from_be_bytes(instruction[..2].try_into().unwrap());
        if operation.policy == 2 && matches!(opcode, 0x4eba | 0x4efa) && length == 4 {
            let displacement = i16::from_be_bytes(instruction[2..4].try_into().unwrap()) as i64;
            let absolute_target = source_address as i64 + cursor as i64 + 2 + displacement;
            if !(0..=u32::MAX as i64).contains(&absolute_target) {
                return Err("M68k PC-relative target is outside 32-bit address space".into());
            }
            let relocated_pc = target_address as i64 + output.len() as i64 + 2;
            let relocated_displacement = absolute_target - relocated_pc;
            if (i16::MIN as i64..=i16::MAX as i64).contains(&relocated_displacement) {
                output.extend_from_slice(&opcode.to_be_bytes());
                output.extend_from_slice(&(relocated_displacement as i16).to_be_bytes());
            } else {
                let absolute_opcode: u16 = if opcode == 0x4eba { 0x4eb9 } else { 0x4ef9 };
                output.extend_from_slice(&absolute_opcode.to_be_bytes());
                output.extend_from_slice(&(absolute_target as u32).to_be_bytes());
            }
        } else {
            output.extend_from_slice(instruction);
        }
        cursor += length;
    }
    if output.len() != operation.target_length {
        return Err("M68k relocated length differs from recipe".into());
    }
    Ok(output)
}

fn reconstruct_runtime(
    stock_os: &[u8],
    runtime: &RuntimeSpec,
    public_payload: &[u8],
) -> Result<Vec<u8>, String> {
    let mut output = vec![0u8; runtime.raw.size];
    let mut coverage = vec![false; runtime.raw.size];
    for (index, range) in runtime.public_ranges.iter().enumerate() {
        mark_range(
            &mut coverage,
            range.target_offset,
            range.length,
            &format!("public runtime range {index}"),
        )?;
        let payload_end = range
            .payload_offset
            .checked_add(range.length)
            .ok_or_else(|| format!("public runtime range {index} payload overflows"))?;
        let source = public_payload
            .get(range.payload_offset..payload_end)
            .ok_or_else(|| format!("public runtime range {index} exceeds payload"))?;
        output[range.target_offset..range.target_offset + range.length].copy_from_slice(source);
    }
    for (index, operation) in runtime.stock_operations.iter().enumerate() {
        mark_range(
            &mut coverage,
            operation.target_offset,
            operation.target_length,
            &format!("local stock operation {index}"),
        )?;
        let source_end = operation
            .source_offset
            .checked_add(operation.source_length)
            .ok_or_else(|| format!("local stock operation {index} source overflows"))?;
        let source = stock_os
            .get(operation.source_offset..source_end)
            .ok_or_else(|| format!("local stock operation {index} exceeds stock OS"))?;
        let relocated = match operation.kind {
            0 => source.to_vec(),
            1 => relocate_m68k(source, operation)?,
            _ => return Err(format!("local stock operation {index} kind differs")),
        };
        if relocated.len() != operation.target_length {
            return Err(format!(
                "local stock operation {index} target length differs"
            ));
        }
        output[operation.target_offset..operation.target_offset + operation.target_length]
            .copy_from_slice(&relocated);
    }
    if coverage.iter().any(|covered| !covered) {
        return Err("runtime reconstruction leaves an unclassified byte".into());
    }
    verify_identity("locally reconstructed runtime", &output, &runtime.raw)?;
    Ok(output)
}

fn reconstruct_append(
    stock_os: &[u8],
    recipe: &BuildRecipe,
    public_payload: &[u8],
) -> Result<Vec<u8>, String> {
    let append = &recipe.append;
    let loader = public_blob(public_payload, &append.loader, "loader")?;
    let stage = public_blob(public_payload, &append.stage_header, "stage header")?;
    let runtime = reconstruct_runtime(stock_os, &append.runtime, public_payload)?;
    let compressed = pack(&runtime, recipe.build.max_candidates)?;
    let runtime_size: u32 = runtime
        .len()
        .try_into()
        .map_err(|_| "runtime is too large for its header".to_string())?;
    let mut packed_runtime = Vec::with_capacity(8 + compressed.len());
    packed_runtime.extend_from_slice(PACKED_RUNTIME_MAGIC);
    packed_runtime.extend_from_slice(&runtime_size.to_be_bytes());
    packed_runtime.extend_from_slice(&compressed);
    verify_identity(
        "locally packed runtime",
        &packed_runtime,
        &append.runtime.packed,
    )?;
    let mut output = Vec::with_capacity(append.length);
    output.extend_from_slice(loader);
    output.extend_from_slice(stage);
    output.extend_from_slice(&packed_runtime);
    verify_identity(
        "locally reconstructed append",
        &output,
        &Identity {
            size: append.length,
            sha256: append.sha256.clone(),
        },
    )?;
    Ok(output)
}

fn nibbled_byte(high: u8, low: u8) -> Result<u8, String> {
    if high > 0x0f || low > 0x0f {
        return Err("SysEx metadata contains a non-nibble byte".into());
    }
    Ok((high << 4) | low)
}

fn unpack_7bit(payload: &[u8], high_order: bool) -> Result<Vec<u8>, String> {
    let mut output = Vec::with_capacity(payload.len() * 7 / 8 + 7);
    for group in payload.chunks(8) {
        if group.is_empty() {
            break;
        }
        let flags = group[0];
        if flags > 0x7f || group[1..].iter().any(|byte| *byte > 0x7f) {
            return Err("SysEx payload contains a non-MIDI-safe byte".into());
        }
        for (index, byte) in group[1..].iter().copied().enumerate() {
            let bit = if high_order { 6 - index } else { index };
            output.push(byte | (((flags >> bit) & 1) << 7));
        }
    }
    Ok(output)
}

fn packet_checksum(offset: usize, decoded: &[u8]) -> u8 {
    let offset_sum = ((offset >> 16) & 0xff) + ((offset >> 8) & 0xff) + (offset & 0xff);
    decoded
        .iter()
        .fold(offset_sum, |sum, byte| sum + *byte as usize) as u8
}

fn decode_firmware(raw: &[u8]) -> Result<Vec<u8>, String> {
    let mut output = Vec::new();
    let mut next_offset: Option<usize> = None;
    let mut declared_total: Option<usize> = None;
    let mut position = 0usize;

    while position < raw.len() {
        if raw[position] != 0xf0 {
            position += 1;
            continue;
        }
        let relative_end = raw[position + 1..].iter().position(|byte| *byte == 0xf7);
        let Some(relative_end) = relative_end else {
            return Err("unterminated SysEx message".into());
        };
        let end = position + 1 + relative_end;
        let message = &raw[position..=end];
        position = end + 1;

        if message.len() < 8 || message[1..4] != MANUFACTURER {
            continue;
        }
        if message[4] != PRODUCT || message[5] != SUBPRODUCT {
            continue;
        }
        let command = message[6];
        let body = &message[7..message.len() - 1];
        if command == DATA_CMD {
            if body.is_empty() {
                continue;
            }
            if body.len() < 8 {
                return Err("SysEx data packet metadata is truncated".into());
            }
            let checksum = nibbled_byte(body[0], body[1])?;
            let offset = ((nibbled_byte(body[2], body[3])? as usize) << 16)
                | ((nibbled_byte(body[4], body[5])? as usize) << 8)
                | nibbled_byte(body[6], body[7])? as usize;
            let high = unpack_7bit(&body[8..], true)?;
            let decoded = if packet_checksum(offset, &high) == checksum {
                high
            } else {
                let low = unpack_7bit(&body[8..], false)?;
                if packet_checksum(offset, &low) != checksum {
                    return Err(format!("SysEx checksum mismatch at offset 0x{offset:06x}"));
                }
                low
            };
            let expected_offset = *next_offset.get_or_insert(offset);
            if offset != expected_offset {
                return Err(format!(
                    "non-contiguous SysEx packet at 0x{offset:06x}; expected 0x{expected_offset:06x}"
                ));
            }
            next_offset = Some(offset + decoded.len());
            output.extend_from_slice(&decoded);
        } else if command == FINAL_CMD {
            if body.len() != 6 {
                return Err("SysEx final packet size is malformed".into());
            }
            declared_total = Some(
                ((nibbled_byte(body[0], body[1])? as usize) << 16)
                    | ((nibbled_byte(body[2], body[3])? as usize) << 8)
                    | nibbled_byte(body[4], body[5])? as usize,
            );
        }
    }
    let declared = declared_total.ok_or_else(|| "SysEx has no final size packet".to_string())?;
    if declared != output.len() {
        return Err(format!(
            "SysEx declares {declared} bytes but contains {}",
            output.len()
        ));
    }
    Ok(output)
}

fn parse_container(decoded: &[u8]) -> Result<Container<'_>, String> {
    if decoded.len() < CONTAINER_HEADER_SIZE {
        return Err("ELEK container is truncated".into());
    }
    if &decoded[..4] != b"ELEK" {
        return Err("ELEK container magic differs".into());
    }
    let product = std::str::from_utf8(&decoded[4..8])
        .map_err(|_| "ELEK product is not ASCII")?
        .to_string();
    let version = std::str::from_utf8(&decoded[13..18])
        .map_err(|_| "ELEK version is not ASCII")?
        .to_string();
    let packed_length = u32::from_be_bytes(decoded[18..22].try_into().unwrap()) as usize;
    let declared_sum = u32::from_be_bytes(decoded[22..26].try_into().unwrap());
    let packed_end = CONTAINER_HEADER_SIZE
        .checked_add(packed_length)
        .ok_or_else(|| "ELEK packed length overflows".to_string())?;
    if packed_end > decoded.len() {
        return Err("ELEK packed stream extends past the container".into());
    }
    let packed = &decoded[CONTAINER_HEADER_SIZE..packed_end];
    let actual_sum = packed
        .iter()
        .fold(0u32, |sum, byte| sum.wrapping_add(*byte as u32));
    if actual_sum != declared_sum {
        return Err("ELEK packed checksum differs".into());
    }
    if decoded[packed_end..].iter().any(|byte| *byte != 0) {
        return Err("ELEK container trailer is not zero-filled".into());
    }
    Ok(Container {
        product,
        version,
        packed,
    })
}

fn build_container(template: &[u8], packed: &[u8], version: &str) -> Result<Vec<u8>, String> {
    let _source = parse_container(template)?;
    if version.len() != 5 || !version.is_ascii() {
        return Err("output version must contain five ASCII bytes".into());
    }
    let packed_length: u32 = packed
        .len()
        .try_into()
        .map_err(|_| "packed stream is too large".to_string())?;
    let packed_sum = packed
        .iter()
        .fold(0u32, |sum, byte| sum.wrapping_add(*byte as u32));
    let mut output = Vec::with_capacity(CONTAINER_HEADER_SIZE + packed.len() + 3);
    output.extend_from_slice(&template[..13]);
    output.extend_from_slice(version.as_bytes());
    output.extend_from_slice(&packed_length.to_be_bytes());
    output.extend_from_slice(&packed_sum.to_be_bytes());
    output.extend_from_slice(packed);
    let padding = (2 + 4 - output.len() % 4) % 4;
    output.resize(output.len() + padding, 0);
    Ok(output)
}

struct BitReader<'a> {
    source: &'a [u8],
    position: usize,
    tag: u32,
}

impl<'a> BitReader<'a> {
    fn new(source: &'a [u8]) -> Self {
        Self {
            source,
            position: 0,
            tag: 0,
        }
    }

    fn read_byte(&mut self) -> Result<u8, String> {
        let byte = self
            .source
            .get(self.position)
            .copied()
            .ok_or_else(|| format!("packed stream ended at 0x{:x}", self.position))?;
        self.position += 1;
        Ok(byte)
    }

    fn next_bit(&mut self) -> Result<u32, String> {
        self.tag = self.tag.wrapping_shl(1);
        if self.tag & 0xff == 0 {
            let byte = self.read_byte()?;
            self.tag = ((byte as u32) << 1) | 1;
            Ok(((byte >> 7) & 1) as u32)
        } else {
            Ok((self.tag >> 8) & 1)
        }
    }

    fn next_gamma(&mut self) -> Result<u32, String> {
        let mut value = 1u32;
        loop {
            value = value
                .checked_mul(2)
                .and_then(|next| next.checked_add(self.next_bit().ok()?))
                .ok_or_else(|| "packed gamma value overflows".to_string())?;
            if self.next_bit()? == 1 {
                return Ok(value);
            }
        }
    }
}

fn depack(source: &[u8]) -> Result<Vec<u8>, String> {
    let mut reader = BitReader::new(source);
    let mut output = Vec::new();
    let mut last_offset = 1usize;
    loop {
        if reader.next_bit()? == 1 {
            output.push(reader.read_byte()?);
            continue;
        }
        let gamma = reader.next_gamma()?;
        let offset = if gamma == 2 {
            last_offset
        } else {
            let byte = reader.read_byte()? as u32;
            let raw = gamma
                .wrapping_mul(256)
                .wrapping_add(byte)
                .wrapping_sub(0x300);
            if raw == u32::MAX {
                if reader.position != source.len() {
                    return Err("packed stream has bytes after its end marker".into());
                }
                return Ok(output);
            }
            let offset = raw as usize + 1;
            last_offset = offset;
            offset
        };
        if offset == 0 || offset > output.len() {
            return Err(format!("invalid packed match offset 0x{offset:x}"));
        }
        let mut length = ((reader.next_bit()? << 1) | reader.next_bit()?) as usize;
        if length == 0 {
            length = reader.next_gamma()? as usize + 2;
        }
        if offset > MAX_OFFSET_FOR_LEN2 {
            length += 1;
        }
        for _ in 0..=length {
            let byte = output[output.len() - offset];
            output.push(byte);
        }
    }
}

#[derive(Debug)]
enum Operation {
    Literal(u8),
    Match { offset: usize, length: usize },
}

fn hash3(bytes: &[u8]) -> usize {
    let key = ((bytes[0] as u32) << 16) | ((bytes[1] as u32) << 8) | bytes[2] as u32;
    ((key.wrapping_mul(2_654_435_761) >> (32 - HASH3_BITS)) & HASH3_MASK) as usize
}

fn hash2(bytes: &[u8]) -> usize {
    ((bytes[0] as usize) << 8) | bytes[1] as usize
}

fn match_length(data: &[u8], candidate: usize, position: usize) -> usize {
    let offset = position - candidate;
    let limit = (data.len() - position).min(MAX_MATCH_LEN);
    let direct_limit = offset.min(limit);
    let mut length = 0usize;
    while length < direct_limit && data[candidate + length] == data[position + length] {
        length += 1;
    }
    if length == direct_limit && length < limit {
        while length < limit && data[candidate + (length % offset)] == data[position + length] {
            length += 1;
        }
    }
    length
}

fn insert_position(
    data: &[u8],
    position: usize,
    head3: &mut [i32],
    chain3: &mut [i32],
    head2: &mut [i32],
    chain2: &mut [i32],
) {
    if position + 1 < data.len() {
        let key = hash2(&data[position..]);
        chain2[position] = head2[key];
        head2[key] = position as i32;
    }
    if position + 2 < data.len() {
        let key = hash3(&data[position..]);
        chain3[position] = head3[key];
        head3[key] = position as i32;
    }
}

fn greedy_parse(data: &[u8], max_candidates: usize) -> Vec<Operation> {
    if data.is_empty() {
        return Vec::new();
    }
    let mut head3 = vec![-1i32; HASH3_SIZE];
    let mut head2 = vec![-1i32; HASH2_SIZE];
    let mut chain3 = vec![-1i32; data.len()];
    let mut chain2 = vec![-1i32; data.len()];
    let mut operations = Vec::with_capacity(data.len() / 2);
    let mut position = 0usize;

    while position < data.len() {
        let mut best_offset = 0usize;
        let mut best_length = 0usize;
        if position + 2 < data.len() {
            let mut candidate = head3[hash3(&data[position..])];
            let mut tried = 0usize;
            while candidate >= 0 && tried < max_candidates {
                let candidate_position = candidate as usize;
                let offset = position - candidate_position;
                let length = match_length(data, candidate_position, position);
                let minimum = if offset > MAX_OFFSET_FOR_LEN2 { 3 } else { 2 };
                if length >= minimum && length > best_length {
                    best_offset = offset;
                    best_length = length;
                    if best_length == MAX_MATCH_LEN {
                        break;
                    }
                }
                candidate = chain3[candidate_position];
                tried += 1;
            }
        }
        if best_length < 2 && position + 1 < data.len() {
            let candidate = head2[hash2(&data[position..])];
            if candidate >= 0 {
                let offset = position - candidate as usize;
                if offset <= MAX_OFFSET_FOR_LEN2 {
                    best_offset = offset;
                    best_length = 2;
                }
            }
        }

        let advance = if best_length >= 2 {
            operations.push(Operation::Match {
                offset: best_offset,
                length: best_length,
            });
            best_length
        } else {
            operations.push(Operation::Literal(data[position]));
            1
        };
        let end = position + advance;
        while position < end {
            insert_position(
                data,
                position,
                &mut head3,
                &mut chain3,
                &mut head2,
                &mut chain2,
            );
            position += 1;
        }
    }
    operations
}

fn gamma_bits(value: u32) -> Result<Vec<u8>, String> {
    if value < 2 {
        return Err(format!("gamma value must be at least 2, got {value}"));
    }
    let highest = 31 - value.leading_zeros();
    let mut bits = Vec::with_capacity(highest as usize * 2);
    for bit_index in (0..highest).rev() {
        bits.push(((value >> bit_index) & 1) as u8);
        bits.push(if bit_index == 0 { 1 } else { 0 });
    }
    Ok(bits)
}

fn length_bits(length_read: usize) -> Result<Vec<u8>, String> {
    match length_read {
        1 => Ok(vec![0, 1]),
        2 => Ok(vec![1, 0]),
        3 => Ok(vec![1, 1]),
        0 => Err("encoded match length is zero".into()),
        _ => {
            let mut bits = vec![0, 0];
            bits.extend(gamma_bits((length_read - 2) as u32)?);
            Ok(bits)
        }
    }
}

fn emit(operations: &[Operation]) -> Result<Vec<u8>, String> {
    let mut tag_bits: Vec<u8> = Vec::new();
    let mut emissions: Vec<(usize, u8)> = Vec::new();
    let mut last_offset: Option<usize> = None;
    for operation in operations {
        match *operation {
            Operation::Literal(byte) => {
                tag_bits.push(1);
                emissions.push((tag_bits.len() - 1, byte));
            }
            Operation::Match { offset, length } => {
                tag_bits.push(0);
                if last_offset == Some(offset) {
                    tag_bits.extend(gamma_bits(2)?);
                } else {
                    let raw_offset = offset - 1;
                    let gamma = (raw_offset + 0x300) / 0x100;
                    let inline_byte = ((raw_offset + 0x300) % 0x100) as u8;
                    tag_bits.extend(gamma_bits(gamma as u32)?);
                    emissions.push((tag_bits.len() - 1, inline_byte));
                }
                let length_read = length - if offset > MAX_OFFSET_FOR_LEN2 { 2 } else { 1 };
                tag_bits.extend(length_bits(length_read)?);
                last_offset = Some(offset);
            }
        }
    }
    tag_bits.push(0);
    tag_bits.extend(gamma_bits(0x0100_0002)?);
    emissions.push((tag_bits.len() - 1, 0xff));
    while !tag_bits.len().is_multiple_of(8) {
        tag_bits.push(0);
    }

    let mut output = Vec::new();
    let mut emission_index = 0usize;
    for group_start in (0..tag_bits.len()).step_by(8) {
        let mut tag = 0u8;
        for bit_index in 0..8 {
            tag |= tag_bits[group_start + bit_index] << (7 - bit_index);
        }
        output.push(tag);
        let group_end = group_start + 8;
        while emission_index < emissions.len() && emissions[emission_index].0 < group_end {
            output.push(emissions[emission_index].1);
            emission_index += 1;
        }
    }
    if emission_index != emissions.len() {
        return Err("not all packed inline bytes were emitted".into());
    }
    Ok(output)
}

fn pack(data: &[u8], max_candidates: usize) -> Result<Vec<u8>, String> {
    emit(&greedy_parse(data, max_candidates))
}

fn pack_7bit(data: &[u8]) -> Vec<u8> {
    let mut output = Vec::with_capacity(data.len() + data.len().div_ceil(7));
    for group in data.chunks(7) {
        let mut flags = 0u8;
        for (index, byte) in group.iter().copied().enumerate() {
            flags |= ((byte >> 7) & 1) << (6 - index);
        }
        output.push(flags);
        output.extend(group.iter().map(|byte| byte & 0x7f));
    }
    output
}

fn nibbles(byte: u8) -> [u8; 2] {
    [(byte >> 4) & 0x0f, byte & 0x0f]
}

fn encode_firmware(decoded: &[u8]) -> Result<Vec<u8>, String> {
    if decoded.len() > 0x00ff_ffff {
        return Err("firmware exceeds the SysEx 24-bit size".into());
    }
    let mut output = Vec::with_capacity(decoded.len() * 4 / 3);
    for (packet_index, chunk) in decoded.chunks(PACKET_DECODED_SIZE).enumerate() {
        let offset = START_OFFSET + packet_index * PACKET_DECODED_SIZE;
        let offset_high = ((offset >> 16) & 0xff) as u8;
        let offset_middle = ((offset >> 8) & 0xff) as u8;
        let offset_low = (offset & 0xff) as u8;
        let checksum = chunk.iter().fold(
            offset_high as usize + offset_middle as usize + offset_low as usize,
            |sum, byte| sum + *byte as usize,
        ) as u8;
        output.extend_from_slice(&[0xf0, MANUFACTURER[0], MANUFACTURER[1], MANUFACTURER[2]]);
        output.extend_from_slice(&[PRODUCT, SUBPRODUCT, DATA_CMD]);
        output.extend_from_slice(&nibbles(checksum));
        output.extend_from_slice(&nibbles(offset_high));
        output.extend_from_slice(&nibbles(offset_middle));
        output.extend_from_slice(&nibbles(offset_low));
        output.extend_from_slice(&pack_7bit(chunk));
        output.push(0xf7);
    }
    output.extend_from_slice(&[0xf0, 0x00, 0x20, 0x3c, PRODUCT, SUBPRODUCT, DATA_CMD, 0xf7]);
    let total = decoded.len();
    output.extend_from_slice(&[0xf0, 0x00, 0x20, 0x3c, PRODUCT, SUBPRODUCT, FINAL_CMD]);
    output.extend_from_slice(&nibbles(((total >> 16) & 0xff) as u8));
    output.extend_from_slice(&nibbles(((total >> 8) & 0xff) as u8));
    output.extend_from_slice(&nibbles((total & 0xff) as u8));
    output.push(0xf7);
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn packer_round_trips_repeated_data() {
        let mut source: Vec<u8> = (0u8..=255).cycle().take(2048).collect();
        source.extend(b"Octatrack".repeat(1000));
        source.extend(vec![0; 5000]);
        let packed = pack(&source, 4096).unwrap();
        assert_eq!(depack(&packed).unwrap(), source);
    }

    #[test]
    fn seven_bit_transport_round_trips() {
        let source: Vec<u8> = (0u8..=255).collect();
        let packed = pack_7bit(&source);
        assert_eq!(unpack_7bit(&packed, true).unwrap(), source);
    }

    #[test]
    fn gamma_two_matches_python_encoder() {
        assert_eq!(gamma_bits(2).unwrap(), [0, 1]);
        assert_eq!(gamma_bits(3).unwrap(), [1, 1]);
    }

    #[test]
    fn identity_size_mismatch_reports_actual_and_expected_sha256() {
        let data = b"wrong";
        let identity = Identity {
            size: 6,
            sha256: sha256_hex(b"source"),
        };
        let error = verify_identity("stock SysEx", data, &identity).unwrap_err();

        assert!(error.contains(&sha256_hex(data)));
        assert!(error.contains(&identity.sha256));
        assert!(error.contains("5 bytes, expected 6"));
    }
}

pub fn compress(data: &[u8]) -> Result<Vec<u8>, String> { pack(data, 4096) }

pub fn decode_stock(data: &[u8]) -> Result<Vec<u8>, String> {
    let decoded = decode_firmware(data)?;
    let container = parse_container(&decoded)?;
    depack(container.packed)
}

#[cfg(not(target_arch = "wasm32"))]
pub fn firmware_container(data: &[u8]) -> Result<Vec<u8>, String> {
    let decoded = decode_firmware(data)?;
    parse_container(&decoded)?;
    Ok(decoded)
}
