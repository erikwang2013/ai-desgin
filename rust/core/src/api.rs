
/// Query available design plugins from the Rust side.
pub fn list_plugins() -> String {
    let plugins: Vec<serde_json::Value> = vec![
        serde_json::json!({"id": "com.aidesign.figma", "name": "Figma", "version": "1.0.3", "script_language": "javascript"}),
        serde_json::json!({"id": "com.aidesign.blender", "name": "Blender", "version": "1.0.3", "script_language": "python"}),
        serde_json::json!({"id": "com.aidesign.autocad", "name": "AutoCAD", "version": "1.0.3", "script_language": "lisp"}),
        serde_json::json!({"id": "com.aidesign.photoshop", "name": "Photoshop", "version": "1.0.3", "script_language": "javascript"}),
    ];
    serde_json::to_string(&plugins).unwrap_or_else(|_| "[]".into())
}

/// Get the capabilities of a specific plugin by id.
pub fn get_plugin_capabilities(plugin_id: String) -> String {
    match plugin_id.as_str() {
        "figma" => serde_json::json!({
            "actions": ["create_canvas", "add_rectangle", "add_text", "set_fill", "export_png", "export_svg"],
            "file_formats": ["fig", "png", "svg", "pdf"]
        }).to_string(),
        "blender" => serde_json::json!({
            "actions": ["create_cube", "create_sphere", "export_fbx", "export_obj", "render_image"],
            "file_formats": ["blend", "fbx", "obj", "glb", "stl"]
        }).to_string(),
        "autocad" => serde_json::json!({
            "actions": ["draw_line", "draw_circle", "create_layer", "set_units", "export_dwg"],
            "file_formats": ["dwg", "dxf", "pdf"]
        }).to_string(),
        _ => "{}".into(),
    }
}
