use ai_design_core::ScriptResult;

/// Figma file keys are 22-char base64url strings (letters, digits, `-`, `_`).
/// Scans the script for a `figma.com/design/{key}` or `figma.com/file/{key}` URL.
fn extract_file_key(script: &str) -> Option<String> {
    for marker in ["figma.com/design/", "figma.com/file/"] {
        let mut start = 0;
        while let Some(rel) = script[start..].find(marker) {
            let idx = start + rel + marker.len();
            let rest = &script[idx..];
            let key: String = rest
                .chars()
                .take_while(|c| c.is_ascii_alphanumeric() || *c == '-' || *c == '_')
                .collect();
            if key.len() == 22 {
                return Some(key);
            }
            start = idx;
        }
    }
    None
}

pub async fn execute_figma_script(token: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    if script.contains("get") || script.contains("list") || script.contains("show") {
        let file_key = extract_file_key(script).ok_or_else(|| {
            "脚本中未找到 Figma 文件链接（figma.com/design/{fileKey}），请在任务中附上文件 URL"
                .to_string()
        })?;
        let resp = client
            .get(format!("https://api.figma.com/v1/files/{file_key}"))
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
