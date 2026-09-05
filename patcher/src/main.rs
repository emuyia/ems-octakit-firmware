use std::{env, fs, process::ExitCode};
mod card;

fn run() -> Result<(), String> {
    let args: Vec<_> = env::args_os().skip(1).collect();
    if args.len() != 3 {
        return Err("usage: ot_patcher <decode|pack|build|card> INPUT OUTPUT".into());
    }
    let input = fs::read(&args[1]).map_err(|e| e.to_string())?;
    let output = match args[0].to_str() {
        Some("decode") => ot_patcher::decode_stock(&input)?,
        Some("pack") => ot_patcher::compress(&input)?,
        Some("card") => card::encode(&ot_patcher::firmware_container(&input)?)?,
        Some("build") => {
            let (output, report) = ot_patcher::build_firmware_bytes(&input)?;
            println!("{report}");
            output
        }
        _ => return Err("unknown operation".into()),
    };
    fs::write(&args[2], output).map_err(|e| e.to_string())
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}
