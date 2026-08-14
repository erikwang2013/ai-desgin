use crate::registry;

// FFI 边界层：函数均以 String 入出参，FRB 只绑定函数签名不生成自定义类型。
// 数据源统一来自 registry（运行时权威注册表），Dart 侧解码 JSON。

/// 全量内置插件注册表 JSON。
pub fn get_builtin_plugins() -> String {
    registry::get_builtin_plugins()
}

/// 单个插件能力 JSON；未命中返回 "{}"。
pub fn get_plugin_capabilities(plugin_id: String) -> String {
    registry::get_plugin_capabilities(&plugin_id)
}

/// Rust 内核版本号，供 App 显示「Rust 内核已连接」状态。
pub fn rust_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builtin_plugins_json_is_valid_array() {
        let value: serde_json::Value =
            serde_json::from_str(&get_builtin_plugins()).expect("invalid JSON");
        assert!(value.as_array().is_some_and(|a| a.len() >= 60));
    }

    #[test]
    fn capabilities_hit_and_miss_through_api() {
        let hit: serde_json::Value =
            serde_json::from_str(&get_plugin_capabilities("blender".to_string())).unwrap();
        assert_eq!(hit["file_formats"][0], "blend");
        assert_eq!(get_plugin_capabilities("nonexistent".to_string()), "{}");
    }

    #[test]
    fn empty_plugin_id_returns_miss() {
        assert_eq!(get_plugin_capabilities(String::new()), "{}");
    }

    #[test]
    fn long_plugin_id_does_not_panic() {
        // FFI 边界输入不可信：超长 id 必须安全返回未命中，而非崩溃。
        let long = "a".repeat(1_000_000);
        assert_eq!(get_plugin_capabilities(long), "{}");
    }

    #[test]
    fn invalid_utf8_plugin_id_does_not_panic() {
        // FRB 以字节构建 String，不做 UTF-8 校验；非法 UTF-8 的 id 必须
        // 安全走字节比较路径返回未命中。safe Rust 无法直接构造此类 String，
        // 仅测试内使用 unchecked 构造模拟 FFI 传入。
        let id = unsafe { String::from_utf8_unchecked(vec![0xff, 0xfe, 0x80, 0x41]) };
        assert_eq!(get_plugin_capabilities(id), "{}");
    }

    #[test]
    fn rust_version_is_non_empty_semver() {
        let v = rust_version();
        assert!(!v.is_empty());
        assert!(v.split('.').count() >= 2, "unexpected version string: {v}");
    }
}
