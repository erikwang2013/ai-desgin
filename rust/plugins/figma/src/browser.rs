pub fn open_figma_file(file_key: &str) -> Result<(), String> {
    let url = format!("https://www.figma.com/file/{}", file_key);
    webbrowser::open(&url).map_err(|e| format!("Failed to open browser: {}", e))
}
