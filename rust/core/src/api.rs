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
