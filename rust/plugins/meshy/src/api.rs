use ai_design_core::ScriptResult;
use serde::{Deserialize, Serialize};

/// Meshy REST API client for AI-powered 3D model generation.
///
/// Meshy provides AI-based 3D content creation:
/// - Text-to-3D: generate 3D models from text prompts
/// - Image-to-3D: convert images to 3D models
/// - Texture generation: generate textures for existing models
/// - Model optimization: optimize topology and reduce polygon count

const MESHY_API_BASE: &str = "https://api.meshy.ai";

#[derive(Debug, Serialize, Deserialize)]
struct MeshyTaskRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    image_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    target_format: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    art_style: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    negative_prompt: Option<String>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct MeshyTaskResponse {
    id: String,
    status: String,
    #[serde(default)]
    output: Vec<MeshyOutput>,
    error: Option<String>,
    #[serde(default)]
    progress: f64,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct MeshyOutput {
    urls: Vec<String>,
    format: Option<String>,
}

/// Execute a request against the Meshy API based on the script content.
pub async fn execute_meshy_request(api_key: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();
    let script_lower = script.to_lowercase();

    if script_lower.contains("文字生成3d")
        || script_lower.contains("text")
        || script_lower.contains("文字生成")
    {
        text_to_3d(client, api_key, script).await
    } else if script_lower.contains("图片生成3d")
        || script_lower.contains("image")
        || script_lower.contains("图片生成")
    {
        image_to_3d(client, api_key, script).await
    } else if script_lower.contains("纹理") || script_lower.contains("texture") {
        generate_texture(client, api_key, script).await
    } else if script_lower.contains("优化") || script_lower.contains("optimize") {
        optimize_model(client, api_key, script).await
    } else if script_lower.contains("export") || script_lower.contains("导出") {
        export_model(client, api_key, script).await
    } else {
        // Default to text-to-3D
        text_to_3d(client, api_key, script).await
    }
}

/// Generate a 3D model from a text prompt.
async fn text_to_3d(
    client: reqwest::Client,
    api_key: &str,
    script: &str,
) -> Result<ScriptResult, String> {
    let request = MeshyTaskRequest {
        prompt: Some(script.to_string()),
        image_url: None,
        model_url: None,
        target_format: Some("glb".into()),
        art_style: None,
        negative_prompt: None,
    };

    let resp = client
        .post(format!("{}/v1/text-to-3d", MESHY_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Meshy API request failed: {}", e))?;

    handle_meshy_response(resp).await
}

/// Generate a 3D model from an image URL.
async fn image_to_3d(
    client: reqwest::Client,
    api_key: &str,
    script: &str,
) -> Result<ScriptResult, String> {
    let request = MeshyTaskRequest {
        prompt: Some(script.to_string()),
        image_url: Some(script.to_string()),
        model_url: None,
        target_format: Some("glb".into()),
        art_style: None,
        negative_prompt: None,
    };

    let resp = client
        .post(format!("{}/v1/image-to-3d", MESHY_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Meshy image-to-3d request failed: {}", e))?;

    handle_meshy_response(resp).await
}

/// Generate textures for an existing model.
async fn generate_texture(
    client: reqwest::Client,
    api_key: &str,
    script: &str,
) -> Result<ScriptResult, String> {
    let request = MeshyTaskRequest {
        prompt: Some(script.to_string()),
        image_url: None,
        model_url: None,
        target_format: None,
        art_style: Some("realistic".into()),
        negative_prompt: None,
    };

    let resp = client
        .post(format!("{}/v1/texture", MESHY_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Meshy texture request failed: {}", e))?;

    handle_meshy_response(resp).await
}

/// Optimize a 3D model (reduce polygon count, fix topology).
async fn optimize_model(
    client: reqwest::Client,
    api_key: &str,
    script: &str,
) -> Result<ScriptResult, String> {
    let request = MeshyTaskRequest {
        prompt: None,
        image_url: None,
        model_url: Some(script.to_string()),
        target_format: Some("glb".into()),
        art_style: None,
        negative_prompt: None,
    };

    let resp = client
        .post(format!("{}/v1/optimize", MESHY_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Meshy optimize request failed: {}", e))?;

    handle_meshy_response(resp).await
}

/// Export a model in the specified format.
async fn export_model(
    client: reqwest::Client,
    api_key: &str,
    script: &str,
) -> Result<ScriptResult, String> {
    let format = if script.to_lowercase().contains("fbx") {
        "fbx"
    } else if script.to_lowercase().contains("obj") {
        "obj"
    } else if script.to_lowercase().contains("stl") {
        "stl"
    } else if script.to_lowercase().contains("usdz") {
        "usdz"
    } else {
        "glb"
    };

    let request = MeshyTaskRequest {
        prompt: None,
        image_url: None,
        model_url: Some(script.to_string()),
        target_format: Some(format.to_string()),
        art_style: None,
        negative_prompt: None,
    };

    let resp = client
        .post(format!("{}/v1/export", MESHY_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Meshy export request failed: {}", e))?;

    handle_meshy_response(resp).await
}

/// Handle the Meshy API response and convert to ScriptResult.
async fn handle_meshy_response(
    resp: reqwest::Response,
) -> Result<ScriptResult, String> {
    if resp.status().is_success() {
        let body: MeshyTaskResponse = resp
            .json()
            .await
            .map_err(|e| format!("Failed to parse Meshy response: {}", e))?;

        if body.status == "completed" || body.status == "succeeded" {
            let artifacts: Vec<String> = body
                .output
                .iter()
                .flat_map(|o| o.urls.clone())
                .collect();

            Ok(ScriptResult::success(
                Some(format!(
                    "Meshy 任务完成 (状态: {})",
                    body.status
                )),
                artifacts,
            ))
        } else if body.status == "failed" {
            Ok(ScriptResult::failure(
                body.error
                    .unwrap_or_else(|| "Meshy 任务失败".into()),
            ))
        } else {
            Ok(ScriptResult::success(
                Some(format!(
                    "Meshy 任务进行中 (状态: {}, 进度: {:.1}%)",
                    body.status,
                    body.progress * 100.0
                )),
                vec![],
            ))
        }
    } else {
        let status = resp.status();
        let body_text = resp
            .text()
            .await
            .unwrap_or_else(|_| "no body".into());
        Ok(ScriptResult::failure(format!(
            "Meshy API 返回 {}: {}",
            status, body_text
        )))
    }
}
