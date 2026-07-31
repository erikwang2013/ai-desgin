
/// Query available design plugins from the Rust side.
pub fn list_plugins() -> String {
    let plugins: Vec<serde_json::Value> = vec![
        serde_json::json!({"id": "com.aidesign.figma", "name": "Figma", "version": env!("CARGO_PKG_VERSION"), "script_language": "javascript"}),
        serde_json::json!({"id": "com.aidesign.blender", "name": "Blender", "version": env!("CARGO_PKG_VERSION"), "script_language": "python"}),
        serde_json::json!({"id": "com.aidesign.autocad", "name": "AutoCAD", "version": env!("CARGO_PKG_VERSION"), "script_language": "lisp"}),
        serde_json::json!({"id": "com.aidesign.photoshop", "name": "Photoshop", "version": env!("CARGO_PKG_VERSION"), "script_language": "javascript"}),
        serde_json::json!({"id": "com.aidesign.illustrator", "name": "Illustrator", "version": env!("CARGO_PKG_VERSION"), "script_language": "javascript"}),
        serde_json::json!({"id": "com.aidesign.sketch", "name": "Sketch", "version": env!("CARGO_PKG_VERSION"), "script_language": "javascript"}),
        serde_json::json!({"id": "com.aidesign.revit", "name": "Revit", "version": env!("CARGO_PKG_VERSION"), "script_language": "python"}),
        serde_json::json!({"id": "com.aidesign.sketchup", "name": "SketchUp", "version": env!("CARGO_PKG_VERSION"), "script_language": "ruby"}),
    ];
    serde_json::to_string(&plugins).unwrap_or_else(|_| "[]".into())
}

/// Get the capabilities of a specific plugin by id.
pub fn get_plugin_capabilities(plugin_id: String) -> String {
    match plugin_id.as_str() {
        "com.aidesign.figma" | "figma" => serde_json::json!({
            "actions": ["create_canvas", "add_rectangle", "add_text", "set_fill", "export_png", "export_svg"],
            "file_formats": ["fig", "png", "svg", "pdf"]
        }).to_string(),
        "com.aidesign.blender" | "blender" => serde_json::json!({
            "actions": ["create_cube", "create_sphere", "export_fbx", "export_obj", "render_image"],
            "file_formats": ["blend", "fbx", "obj", "glb", "stl"]
        }).to_string(),
        "com.aidesign.autocad" | "autocad" => serde_json::json!({
            "actions": ["draw_line", "draw_circle", "create_layer", "set_units", "export_dwg"],
            "file_formats": ["dwg", "dxf", "pdf"]
        }).to_string(),
        "com.aidesign.illustrator" | "illustrator" => serde_json::json!({
            "actions": ["create_artboard", "add_shape", "add_text", "create_path", "set_fill", "export_png", "export_svg"],
            "file_formats": ["ai", "eps", "svg", "pdf", "png"]
        }).to_string(),
        "com.aidesign.sketch" | "sketch" => serde_json::json!({
            "actions": ["create_artboard", "add_shape", "add_text", "set_style", "export_slice", "create_component"],
            "file_formats": ["sketch", "png", "svg", "pdf"]
        }).to_string(),
        "com.aidesign.revit" | "revit" => serde_json::json!({
            "actions": ["create_wall", "create_floor", "create_roof", "place_family", "modify_parameter", "export_ifc"],
            "file_formats": ["rvt", "rfa", "ifc", "dwg", "dxf"]
        }).to_string(),
        "com.aidesign.sketchup" | "sketchup" => serde_json::json!({
            "actions": ["push_pull", "apply_material", "create_scene", "create_section", "export_3d"],
            "file_formats": ["skp", "dae", "kmz", "obj", "stl"]
        }).to_string(),
        _ => "{}".into(),
    }
}
