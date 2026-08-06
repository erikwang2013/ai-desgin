use ai_design_core::ScriptResult;
use std::process::Command;

/// Run a Lychee Slicer CLI command.
///
/// Lychee Slicer supports both resin and FDM slicing with commands like:
///   lychee-slicer --slice --output output.gcode input.stl
///
/// The `script` parameter contains the full command arguments or a description
/// of the operation to perform.
pub fn run_lychee_command(lychee_path: &str, script: &str) -> Result<ScriptResult, String> {
    let args = if script.trim().starts_with("--") {
        parse_cli_args(script)
    } else {
        translate_to_cli(script)
    };

    let mut cmd = Command::new(lychee_path);
    cmd.args(&args);
    let (stdout, stderr, status) = ai_design_core::proc::run_command(&mut cmd)
        .map_err(|e| format!("Failed to execute Lychee Slicer: {e}"))?;

    if status.success() {
        Ok(ScriptResult::success(
            Some(format!("Lychee Slicer 命令执行成功\n输出:\n{}", stdout)),
            extract_output_files(&args),
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Lychee Slicer 命令执行失败 (exit code: {:?})\n错误:\n{}",
            status.code(),
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

/// Translate a high-level operation description into Lychee Slicer CLI arguments.
fn translate_to_cli(script: &str) -> Vec<String> {
    let lower = script.to_lowercase();
    let mut args: Vec<String> = vec![];

    if lower.contains("slice") || lower.contains("切片") {
        args.push("--slice".into());
    }

    if lower.contains("layout") || lower.contains("布局") {
        args.push("--auto-layout".into());
    }

    if lower.contains("support") || lower.contains("支撑") {
        if lower.contains("fdm") {
            args.push("--fdm-support".into());
        } else {
            args.push("--auto-support".into());
        }
    }

    if lower.contains("resin") || lower.contains("树脂") {
        args.push("--printer-type".into());
        args.push("resin".into());
    }

    if lower.contains("fdm") {
        args.push("--printer-type".into());
        args.push("fdm".into());
    }

    if lower.contains("import") || lower.contains("导入") {
        args.push("--import".into());
    }

    // Detect export format
    if lower.contains("ctb") {
        args.push("--format".into());
        args.push("ctb".into());
    } else if lower.contains("gcode") {
        args.push("--format".into());
        args.push("gcode".into());
    } else if lower.contains("lys") || lower.contains("lychee") {
        args.push("--format".into());
        args.push("lys".into());
    }

    // Detect input file from script
    for ext in &[".stl", ".obj", ".3mf"] {
        if let Some(idx) = lower.rfind(ext) {
            let before = &script[..idx];
            if let Some(last_space) = before.rfind(|c: char| c.is_whitespace()) {
                let input_file = script[last_space + 1..=idx + 3].trim().to_string();
                args.push("--output".into());
                let ext_name = ext.trim_start_matches('.');
                let output_name = input_file.replace(ext, &format!(".{}", if ext_name == "stl" { "gcode" } else { ext_name }));
                args.push(output_name);
                args.push(input_file);
                break;
            }
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
