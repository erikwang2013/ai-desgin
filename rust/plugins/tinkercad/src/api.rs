use ai_design_core::ScriptResult;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct ShapeScriptResponse {
    success: bool,
    design_id: Option<String>,
    export_url: Option<String>,
    error: Option<String>,
}

/// Base URL for Tinkercad's web API.
const TINKERCAD_API_BASE: &str = "https://api.tinkercad.com";

/// Execute a Tinkercad ShapeScript via the web API.
///
/// The script is a JavaScript ShapeScript that creates or manipulates 3D shapes.
/// Because Tinkercad is entirely web-based, all operations go through its REST API.
pub async fn execute_tinkercad_script(token: &str, script: &str) -> Result<ScriptResult, String> {
    // Determine operation type from script content
    let script_lower = script.to_lowercase();

    if script_lower.contains("export") || script_lower.contains("导出") {
        // Handle export operations
        let format = if script_lower.contains("stl") {
            "stl"
        } else if script_lower.contains("obj") {
            "obj"
        } else if script_lower.contains("glb") || script_lower.contains("gltf") {
            "glb"
        } else {
            "stl"
        };

        export_design(token, format).await
    } else if script_lower.contains("import") || script_lower.contains("导入") {
        // Handle import operations (e.g., SVG import)
        import_svg(token, script).await
    } else {
        // Handle shape creation / manipulation
        run_shape_script(token, script).await
    }
}

/// Run a ShapeScript to create or manipulate shapes.
async fn run_shape_script(token: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    let resp = client
        .post(format!("{}/v1/shapescripts/execute", TINKERCAD_API_BASE))
        .header("Authorization", format!("Bearer {}", token))
        .header("Content-Type", "application/json")
        .json(&serde_json::json!({
            "script": script,
            "language": "javascript"
        }))
        .send()
        .await
        .map_err(|e| format!("Tinkercad API request failed: {}", e))?;

    if resp.status().is_success() {
        let body: ShapeScriptResponse = resp
            .json()
            .await
            .map_err(|e| format!("Failed to parse response: {}", e))?;

        if body.success {
            Ok(ScriptResult::success(
                Some(format!(
                    "Tinkercad ShapeScript 执行成功\n设计ID: {}",
                    body.design_id.as_deref().unwrap_or("N/A")
                )),
                vec![],
            ))
        } else {
            Ok(ScriptResult::failure(
                body.error
                    .unwrap_or_else(|| "Unknown error".into()),
            ))
        }
    } else {
        let status = resp.status();
        let body_text = resp
            .text()
            .await
            .unwrap_or_else(|_| "no body".into());
        Ok(ScriptResult::failure(format!(
            "Tinkercad API 返回 {}: {}",
            status, body_text
        )))
    }
}

/// Export a design in the specified format.
async fn export_design(token: &str, format: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    let resp = client
        .post(format!(
            "{}/v1/designs/export",
            TINKERCAD_API_BASE
        ))
        .header("Authorization", format!("Bearer {}", token))
        .json(&serde_json::json!({
            "format": format
        }))
        .send()
        .await
        .map_err(|e| format!("Tinkercad export request failed: {}", e))?;

    if resp.status().is_success() {
        let body: ShapeScriptResponse = resp
            .json()
            .await
            .map_err(|e| format!("Failed to parse response: {}", e))?;

        Ok(ScriptResult::success(
            Some(format!("Tinkercad 导出 {} 成功", format.to_uppercase())),
            body.export_url.map(|u| vec![u]).unwrap_or_default(),
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Tinkercad 导出失败: {}",
            resp.status()
        )))
    }
}

/// Import an SVG into Tinkercad.
async fn import_svg(token: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    // Extract SVG URL or data from the script
    let resp = client
        .post(format!("{}/v1/designs/import/svg", TINKERCAD_API_BASE))
        .header("Authorization", format!("Bearer {}", token))
        .json(&serde_json::json!({
            "script_context": script,
            "source": "shape_script"
        }))
        .send()
        .await
        .map_err(|e| format!("Tinkercad SVG import failed: {}", e))?;

    if resp.status().is_success() {
        Ok(ScriptResult::success(
            Some("Tinkercad SVG 导入成功".into()),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Tinkercad SVG 导入失败: {}",
            resp.status()
        )))
    }
}
