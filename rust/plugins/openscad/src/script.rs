use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn run_openscad_script(openscad_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Create a temp directory to hold input .scad and output files
    let temp_dir = tempfile::TempDir::new()
        .map_err(|e| format!("Failed to create temp dir: {}", e))?;

    // Write the SCAD script to a temp file
    let scad_path = temp_dir.path().join("input.scad");
    let mut scad_file = std::fs::File::create(&scad_path)
        .map_err(|e| format!("Failed to create SCAD file: {}", e))?;
    scad_file.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write SCAD script: {}", e))?;

    // Render to STL (default output format)
    let output_stl = temp_dir.path().join("output.stl");
    let output = Command::new(openscad_path)
        .args([
            "-o",
            &output_stl.to_string_lossy(),
            &scad_path.to_string_lossy(),
        ])
        .output()
        .map_err(|e| format!("Failed to execute OpenSCAD: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        let mut artifacts = vec![];
        // Check if the output file was generated
        if output_stl.exists() {
            artifacts.push(output_stl.to_string_lossy().to_string());
        }
        Ok(ScriptResult::success(
            Some(format!(
                "OpenSCAD 脚本执行成功\n输出:\n{}\n{}",
                stdout, stderr
            )),
            artifacts,
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "OpenSCAD 脚本执行失败 (exit code: {:?})\n错误:\n{}",
            output.status.code(),
            stderr
        )))
    }
}
