use ai_design_core::ScriptResult;
use std::process::Command;

/// Run a ChiTuBox CLI command.
///
/// ChiTuBox CLI supports slicing for resin 3D printers with commands like:
///   ChiTuBox --slice --output output.ctb input.stl
///
/// The `script` parameter contains the full command arguments to pass to ChiTuBox.
pub fn run_chitubox_command(chitubox_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Parse the script. If it looks like command-line arguments, use them directly.
    // Otherwise, treat it as a description of the operation to perform.
    let args = if script.trim().starts_with("--") {
        // Direct CLI arguments
        parse_cli_args(script)
    } else {
        // Script describes an operation — translate to CLI args
        translate_to_cli(script)
    };

    let output = Command::new(chitubox_path)
        .args(&args)
        .output()
        .map_err(|e| format!("Failed to execute ChiTuBox: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        Ok(ScriptResult::success(
            Some(format!("ChiTuBox 命令执行成功\n输出:\n{}", stdout)),
            extract_output_files(&args),
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "ChiTuBox 命令执行失败 (exit code: {:?})\n错误:\n{}",
            output.status.code(),
            stderr
        )))
    }
}

/// Parse CLI argument string into a vector of arguments.
fn parse_cli_args(args_str: &str) -> Vec<String> {
    args_str
        .split_whitespace()
        .map(|s| s.to_string())
        .collect()
}

/// Translate a high-level operation description into ChiTuBox CLI arguments.
fn translate_to_cli(script: &str) -> Vec<String> {
    let lower = script.to_lowercase();
    let mut args: Vec<String> = vec![];

    if lower.contains("slice") || lower.contains("切片") {
        args.push("--slice".into());
    }

    if lower.contains("support") || lower.contains("支撑") {
        args.push("--auto-support".into());
    }

    if lower.contains("hollow") || lower.contains("挖空") {
        args.push("--hollow".into());
    }

    if lower.contains("hole") || lower.contains("打孔") {
        args.push("--add-hole".into());
    }

    if lower.contains("export") || lower.contains("导出") {
        args.push("--export".into());
    }

    // Extract output format
    if lower.contains("ctb") {
        args.push("--format".into());
        args.push("ctb".into());
    } else if lower.contains("cbddlp") {
        args.push("--format".into());
        args.push("cbddlp".into());
    } else if lower.contains("photon") {
        args.push("--format".into());
        args.push("photon".into());
    }

    // Set output file if specified
    if let Some(out_idx) = lower.rfind(".stl") {
        // Find the word before .stl
        let before = &script[..out_idx];
        if let Some(last_space) = before.rfind(|c: char| c.is_whitespace()) {
            let input_file = script[last_space + 1..=out_idx + 3].trim().to_string();
            args.push("--output".into());
            let output_name = input_file.replace(".stl", ".ctb");
            args.push(output_name);
            args.push(input_file);
        }
    }

    if args.is_empty() {
        args.push("--help".into());
    }

    args
}

/// Extract output file paths from CLI arguments.
fn extract_output_files(args: &[String]) -> Vec<String> {
    let mut files = vec![];
    let mut i = 0;
    while i < args.len() {
        if (args[i] == "--output" || args[i] == "-o")
            && i + 1 < args.len() {
                files.push(args[i + 1].clone());
            }
        i += 1;
    }
    files
}
