use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn format_autolisp_script(lisp_code: &str) -> String {
    lisp_code.to_string()
}

pub fn run_autocad_script(autocad_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Write AutoLISP script to temp .scr file (AutoCAD script file format)
    let scr_content = format!(
        "(progn\n  {}\n  (princ \"\\nSCRIPT_COMPLETE\")\n)\n",
        script
    );

    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(scr_content.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;
    let temp_path = temp.path().to_string_lossy().to_string();

    let output = Command::new(autocad_path)
        .args(["/b", &temp_path]) // /b runs script on startup
        .output()
        .map_err(|e| format!("Failed to execute AutoCAD: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if stdout.contains("SCRIPT_COMPLETE") || output.status.success() {
        Ok(ScriptResult::success(
            Some(format!("AutoCAD 脚本执行成功\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "AutoCAD 脚本执行失败\nstdout: {}\nstderr: {}",
            stdout, stderr
        )))
    }
}
