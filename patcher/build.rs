use std::{env, fs, path::PathBuf};

fn main() {
    println!("cargo:rerun-if-env-changed=OCTAKIT_GENERATED_DIR");
    if env::var_os("CARGO_FEATURE_EMBEDDED_RECIPE").is_none() {
        return;
    }
    let input = PathBuf::from(
        env::var_os("OCTAKIT_GENERATED_DIR").expect("run the repository build.py first"),
    );
    let output = PathBuf::from(env::var_os("OUT_DIR").unwrap());
    for name in ["firmware.rs", "public-bytes.dat"] {
        let path = input.join(name);
        println!("cargo:rerun-if-changed={}", path.display());
        fs::copy(path, output.join(name)).expect("could not stage generated patcher input");
    }
}
