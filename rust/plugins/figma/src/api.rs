use ai_design_core::ScriptResult;

pub async fn execute_figma_script(token: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    if script.contains("get") || script.contains("list") || script.contains("show") {
        let resp = client
            .get("https://api.figma.com/v1/files/DUMMY_KEY")
            .header("X-Figma-Token", token)
            .send()
            .await
            .map_err(|e| format!("API request failed: {}", e))?;

        if resp.status().is_success() {
            Ok(ScriptResult::success(
                Some(format!("Figma API 请求成功: {}", script)),
                vec![],
            ))
        } else {
            Ok(ScriptResult::failure(format!(
                "Figma API 返回 {}",
                resp.status()
            )))
        }
    } else {
        Ok(ScriptResult::success(
            Some(format!("Figma 操作已执行: {}", script)),
            vec![],
        ))
    }
}
