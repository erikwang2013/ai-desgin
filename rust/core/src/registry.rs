use serde::Serialize;
use std::sync::LazyLock;

/// 内置插件注册表——运行时权威数据源（Dart 侧 builtin_plugins.dart 为回退副本）。
#[derive(Serialize)]
pub struct PluginMeta {
    pub id: &'static str,
    pub name: &'static str,
    pub category: &'static str,
    pub script_language: &'static str,
    pub icon: &'static str,
    pub description: &'static str,
    pub capabilities: Capabilities,
}

#[derive(Serialize)]
pub struct Capabilities {
    pub actions: Vec<&'static str>,
    pub file_formats: Vec<&'static str>,
}

#[allow(clippy::too_many_arguments)] // 数据录入构造器，字段固定
fn p(
    id: &'static str,
    name: &'static str,
    category: &'static str,
    script_language: &'static str,
    icon: &'static str,
    description: &'static str,
    actions: &[&'static str],
    file_formats: &[&'static str],
) -> PluginMeta {
    PluginMeta {
        id,
        name,
        category,
        script_language,
        icon,
        description,
        capabilities: Capabilities {
            actions: actions.to_vec(),
            file_formats: file_formats.to_vec(),
        },
    }
}

static PLUGINS: LazyLock<Vec<PluginMeta>> = LazyLock::new(|| vec![
    p("figma", "Figma", "web", "javascript", "🎨", "UI 设计软件插件，支持创建画布、图层操作、导出等", &["创建画布","添加矩形","添加文本","设置填充","导出PNG"], &["fig","png","svg"]),
    p("sketch", "Sketch", "web", "javascript", "✏️", "macOS UI 设计工具插件，支持画板、图层、导出", &["创建画板","添加形状","导出切片","创建组件"], &["sketch","png","svg","pdf"]),
    p("photoshop", "Photoshop", "ad", "javascript", "🖼️", "图像处理软件插件，支持图层、滤镜、批处理", &["图层操作","滤镜","批处理","导出"], &["psd","png","jpg","tiff"]),
    p("illustrator", "Illustrator", "ad", "javascript", "🖋️", "矢量图形设计软件插件，支持画板、路径、效果", &["创建画板","添加形状","路径操作","导出SVG"], &["ai","eps","svg","pdf"]),
    p("blender", "Blender", "threeD", "python", "🔷", "3D 建模软件插件，支持建模、渲染、导出等", &["创建立方体","创建球体","导出FBX","渲染图像"], &["blend","fbx","obj","glb"]),
    p("sketchup", "SketchUp", "interior", "ruby", "🏠", "3D 建模软件插件，推拉、材质、场景、剖面", &["推拉","材质","场景","剖面"], &["skp","dae","kmz","obj"]),
    p("autocad", "AutoCAD", "arch", "lisp", "📐", "CAD 软件插件，支持绘图、标注、图层管理", &["绘制直线","绘制圆","创建图层","导出DWG"], &["dwg","dxf","pdf"]),
    p("revit", "Revit", "arch", "python", "🏗️", "BIM 建筑设计软件插件，支持墙体、楼板、族、参数", &["创建墙体","创建楼板","放置族","导出IFC"], &["rvt","rfa","ifc","dwg"]),
    p("fusion360", "Fusion 360", "industrial", "python", "⚙️", "工业设计CAD/CAM软件插件，支持草图、建模、装配", &["创建草图","拉伸","倒角","导出STEP"], &["f3d","step","iges","stl"]),
    p("maya", "Maya", "threeD", "python", "🎬", "3D动画与建模软件插件，支持建模、绑定、动画、渲染", &["创建模型","绑定骨骼","动画制作","渲染输出","导出FBX"], &["ma","mb","fbx","obj","alembic"]),
    p("3dsmax", "3ds Max", "threeD", "python", "🏢", "3D建模与渲染软件插件，支持几何体、修改器、动力学", &["创建几何体","修改器","材质编辑","MassFX动力学","导出FBX"], &["max","fbx","obj","3ds"]),
    p("cinema4d", "Cinema 4D", "threeD", "python", "🎥", "3D动态图形软件插件，支持MoGraph、动力学、Redshift渲染", &["创建对象","MoGraph动态图形","动力学模拟","Redshift渲染","导出FBX"], &["c4d","fbx","obj","alembic"]),
    p("indesign", "InDesign", "ad", "javascript", "📰", "桌面出版软件插件，支持文档排版、主页、导出PDF/EPUB", &["创建文档","文本排版","图像置入","主页设置","导出PDF"], &["indd","idml","pdf","epub"]),
    p("aftereffects", "After Effects", "ad", "javascript", "✨", "动态图形与视觉特效软件插件，支持合成、关键帧动画、特效渲染", &["创建合成","添加图层","关键帧动画","应用特效","渲染输出"], &["aep","mogrt","mp4","mov","gif"]),
    p("premierepro", "Premiere Pro", "ad", "javascript", "🎞️", "专业视频编辑软件插件，支持多轨剪辑、调色、音频混音、导出", &["导入素材","剪辑片段","添加转场","调色","导出视频"], &["prproj","mp4","mov","xml"]),
    p("xd", "Adobe XD", "web", "javascript", "🧩", "UI/UX设计软件插件，支持画板、交互原型、设计规范、切图导出", &["创建画板","添加组件","交互原型","设计规范","导出切图"], &["xd","png","svg","pdf"]),
    p("lightroom", "Lightroom", "ad", "lua", "📷", "数字照片管理与编辑软件插件，支持批量调色、预设、RAW处理", &["导入照片","调整曝光","预设应用","批量导出","色彩校正"], &["lrcat","dng","jpg","tiff","raw"]),
    p("animate", "Animate", "ad", "javascript", "🎮", "2D交互动画制作软件插件，支持元件动画、骨骼绑定、HTML5导出", &["创建元件","时间轴动画","骨骼绑定","导出HTML5","发布动画"], &["fla","html","gif","mp4","oam"]),
    p("audition", "Audition", "ad", "javascript", "🎵", "专业音频编辑软件插件，支持多轨混音、降噪、音效处理", &["导入音频","多轨混音","降噪处理","音效添加","导出音频"], &["sesx","wav","mp3","aac"]),
    p("dreamweaver", "Dreamweaver", "web", "javascript", "🌐", "网页设计与代码编辑器插件，支持可视化布局、代码编辑、FTP发布", &["创建页面","代码编辑","实时预览","FTP发布","响应式布局"], &["html","css","js","php","dwt"]),
    p("characteranimator", "Character Animator", "ad", "javascript", "🤖", "2D角色动画软件插件，支持面部捕捉、动作录制、实时驱动", &["导入角色","面部捕捉","动作录制","触发器设置","导出视频"], &["chproj","puppet","mp4","mov"]),
    p("fresco", "Fresco", "ad", "javascript", "🖌️", "数字绘画与插画软件插件，支持矢量和像素笔刷、水彩混合", &["创建画布","矢量绘画","像素笔刷","水彩混合","导出PSD"], &["fresco","psd","png","jpg","svg"]),
    p("dimension", "Dimension", "threeD", "javascript", "📦", "3D产品设计软件插件，支持模型渲染、材质贴图、场景灯光", &["导入模型","材质贴图","灯光设置","场景渲染","导出图像"], &["dn","psd","png","jpg","glb"]),
    p("bridge", "Bridge", "ad", "javascript", "📂", "数字资产管理软件插件，支持文件浏览、批量重命名、元数据管理", &["浏览文件","批量重命名","元数据编辑","关键词标记","文件排序"], &["jpg","png","psd","raw","pdf"]),
    p("acrobat", "Acrobat Pro", "ad", "javascript", "📄", "PDF编辑与文档处理插件，支持创建、编辑、合并、表单、OCR", &["创建PDF","编辑文本","合并文档","表单制作","OCR识别"], &["pdf","docx","xlsx","pptx","jpg"]),
    p("substancepainter", "Substance 3D Painter", "threeD", "python", "🎯", "3D纹理绘制软件插件，支持UV编辑、材质烘焙、智能遮罩", &["导入模型","UV编辑","纹理绘制","材质烘焙","导出贴图"], &["spp","glb","fbx","obj","png"]),
    p("substancedesigner", "Substance 3D Designer", "threeD", "python", "🧬", "3D材质创作软件插件，支持节点材质编辑、程序纹理、函数图表", &["节点编辑","材质生成","程序纹理","函数图表","导出SBSAR"], &["sbs","sbsar","png","tiff","exr"]),
    p("substancesampler", "Substance 3D Sampler", "threeD", "python", "📸", "3D材质采集软件插件，支持照片扫描、HDR环境、AI材质生成", &["照片扫描","材质生成","HDR环境","通道提取","导出材质"], &["sbsar","png","jpg","exr","hdr"]),
    p("substancestager", "Substance 3D Stager", "threeD", "python", "🎪", "3D场景搭建软件插件，支持模型摆放、材质分配、灯光渲染", &["场景搭建","模型摆放","材质分配","灯光渲染","导出图像"], &["stager","glb","png","psd","jpg"]),
    p("substancemodeler", "Substance 3D Modeler", "threeD", "python", "🗿", "VR 3D建模软件插件，支持粘土雕刻、布尔运算、网格重构", &["VR雕刻","粘土建模","布尔运算","网格重构","导出模型"], &["sm3d","glb","fbx","obj","usd"]),
    p("mediaencoder", "Media Encoder", "ad", "javascript", "🔄", "媒体转码软件插件，支持格式转换、预设应用、批量渲染", &["导入队列","格式转换","预设应用","批量渲染","监视文件夹"], &["mp4","mov","avi","wav","jpg"]),
    p("incopy", "InCopy", "ad", "javascript", "📝", "协同文案编辑软件插件，支持样式应用、修订追踪、与InDesign联动", &["编写文案","协同编辑","样式应用","修订追踪","导出文本"], &["icml","incx","docx","txt","rtf"]),
    p("express", "Adobe Express", "web", "javascript", "🚀", "快速设计工具插件，支持模板设计、品牌套用、社交图片一键生成", &["模板选择","快速设计","品牌套用","社交图片","导出发布"], &["jpg","png","mp4","pdf","gif"]),
    p("zw3d", "中望3D", "industrial", "python", "🔧", "国产CAD/CAM软件插件，支持草图、特征建模、装配、工程图", &["创建草图","特征建模","装配设计","工程图","导出STEP"], &["zw3d","step","iges","stl","dwg"]),
    p("3done", "3D One系列", "threeD", "python", "🧒", "青少年3D设计软件插件，支持建模、拉伸、旋转、阵列", &["创建模型","拉伸","旋转","阵列","导出STL"], &["3done","stl","obj"]),
    p("voxeldance", "VoxelDance Additive", "industrial", "python", "🦴", "增材制造数据准备软件插件，支撑生成、切片、路径规划", &["模型导入","支撑生成","切片","路径规划","导出GCode"], &["vda","stl","gcode","3mf"]),
    p("happy3d", "Happy3D", "threeD", "python", "😊", "3D建模软件插件，支持场景编辑、材质贴图、渲染导出", &["创建模型","场景编辑","材质贴图","渲染","导出GLB"], &["h3d","glb","stl","obj"]),
    p("maodou3d", "毛豆科技3D建模软件", "threeD", "python", "🫘", "教育3D建模软件插件，支持模型创建、场景搭建、材质编辑", &["创建模型","场景搭建","材质编辑","导出STL"], &["md3d","stl","obj"]),
    p("makerlab", "MakerLab", "industrial", "python", "🧪", "3D打印管理平台插件，支持切片、打印管理、模型库", &["模型导入","切片","打印管理","模型库","导出GCode"], &["stl","3mf","gcode"]),
    p("crealitycloud", "Creality Cloud", "industrial", "python", "☁️", "云端3D打印平台插件，支持模型上传、云端切片、远程打印", &["模型上传","云端切片","远程打印","模型库","导出GCode"], &["stl","3mf","gcode"]),
    p("flashprint", "FlashPrint", "industrial", "python", "⚡", "3D打印切片软件插件，支持切片配置、支撑编辑、打印预览", &["模型导入","切片配置","支撑编辑","打印预览","导出GCode"], &["stl","obj","3mf","gcode","fpp"]),
    p("flashstudio", "Flash Studio", "industrial", "python", "💡", "3D打印管理软件插件，支持模型编辑、支撑生成、打印管理", &["模型编辑","支撑生成","切片","打印管理","导出GCode"], &["stl","obj","gcode"]),
    p("snapmakerluban", "Snapmaker Luban", "industrial", "python", "🖨️", "多功能CAM软件插件，支持CNC雕刻、激光切割、3D打印", &["模型导入","CNC雕刻","激光切割","3D打印","导出GCode"], &["stl","svg","nc","gcode"]),
    p("snapmakerorca", "Snapmaker Orca", "industrial", "python", "🐋", "3D打印切片软件插件，基于OrcaSlicer，支持校准、打印管理", &["模型导入","切片配置","校准工具","打印管理","导出GCode"], &["stl","3mf","gcode"]),
    p("buildplanner", "Build Planner", "industrial", "python", "📋", "3D打印排布软件插件，支持模型排布、材料估算、时间预估", &["模型排布","打印队列","材料估算","时间预估","导出布局"], &["stl","layout","gcode"]),
    p("flashdental", "FlashDental", "industrial", "python", "🦷", "牙科3D打印软件插件，支持牙模导入、模型编辑、切片", &["牙模导入","模型编辑","支撑生成","切片","导出GCode"], &["stl","3mf","gcode"]),
    p("waxjetprint", "WaxJetPrint", "industrial", "python", "🕯️", "蜡模3D打印软件插件，支持蜡模导入、模型优化、切片", &["蜡模导入","模型优化","支撑生成","切片","导出GCode"], &["stl","wax","gcode"]),
    p("kujiale", "酷家乐", "interior", "javascript", "🏘️", "云设计室内装修软件插件，支持户型绘制、硬装定制、家具布置、全景渲染", &["户型绘制","硬装设计","家具布置","效果图渲染","导出全景图"], &["kujiale","json","jpg","png","全景图"]),
    p("3vjia", "三维家", "interior", "python", "🏡", "3D家居设计软件插件，支持户型导入、定制家具、材质编辑、VR全景渲染", &["户型导入","定制家具","材质编辑","VR渲染","导出CAD"], &["3vjia","json","obj","dwg","jpg"]),
    p("yuanfang", "圆方", "interior", "python", "📏", "室内家具设计软件插件，支持空间规划、家具布局、材质替换、效果图与报价", &["空间规划","家具布局","材质替换","效果渲染","导出报价单"], &["yuanfang","dwg","jpg","xls"]),
    p("solidworks", "SolidWorks", "industrial", "vba", "🔩", "三维CAD设计软件插件，支持参数化建模、装配设计、工程图", &["创建草图","特征建模","装配设计","生成工程图","导出STEP"], &["sldprt","sldasm","step","iges","dwg"]),
    p("freecad", "FreeCAD", "industrial", "python", "🧰", "开源参数化CAD软件插件，支持零件设计、装配约束、导出STL/STEP", &["参数化建模","草图编辑","零件设计","装配约束","导出STL"], &["fcstd","stl","step","iges","dwg"]),
    p("openscad", "OpenSCAD", "industrial", "scad", "📜", "程序化CAD软件插件，支持脚本建模、布尔运算、参数化设计", &["参数化脚本","布尔运算","线性拉伸","旋转体","渲染导出"], &["scad","stl","dxf","svg","off"]),
    p("rhino", "Rhino", "threeD", "python", "🦏", "NURBS曲面建模软件插件，支持曲面设计、网格重建、Grasshopper参数化", &["NURBS建模","曲面编辑","网格重建","渲染导出","Grasshopper参数化"], &["3dm","step","iges","stl","obj"]),
    p("tinkercad", "Tinkercad", "industrial", "python", "🔺", "在线3D设计工具插件，支持形状组合、布尔运算、电路仿真", &["导入STL","形状组合","布尔运算","电路仿真","导出STL"], &["stl","obj","svg","brd"]),
    p("meshy", "Meshy", "threeD", "python", "🧠", "AI 3D模型生成平台插件，支持文字/图片生成模型、纹理生成", &["文字生成3D模型","图片生成模型","模型优化","纹理生成","多格式导出"], &["glb","fbx","obj","usd","stl"]),
    p("cura", "UltiMaker Cura", "industrial", "cli", "🧵", "开源FDM切片软件插件，支持模型导入、切片配置、支撑设置", &["模型导入","切片配置","支撑设置","打印预览","导出GCode"], &["stl","3mf","gcode","obj"]),
    p("prusaslicer", "PrusaSlicer", "industrial", "cli", "🍅", "FDM/树脂切片软件插件，支持多色打印、支撑生成、打印配置", &["模型导入","切片配置","支撑生成","多色打印","导出GCode"], &["stl","3mf","gcode","obj"]),
    p("orcaslicer", "OrcaSlicer", "industrial", "cli", "🐳", "高性能切片软件插件，支持流量校准、多材料、精细支撑", &["模型导入","切片配置","流量校准","支撑编辑","导出GCode"], &["stl","3mf","gcode","obj"]),
    p("simplify3d", "Simplify3D", "industrial", "cli", "🛠️", "专业3D打印切片软件插件，支持多进程设置、精细支撑控制", &["模型导入","切片配置","多进程设置","支撑编辑","导出GCode"], &["stl","obj","gcode","3mf"]),
    p("chitubox", "ChiTuBox", "industrial", "cli", "💧", "树脂3D打印切片软件插件，支持镂空挖孔、支撑生成、CTB导出", &["模型导入","树脂切片","支撑生成","镂空挖孔","导出CTB"], &["stl","3mf","ctb","photon"]),
    p("lychee", "Lychee Slicer", "industrial", "cli", "🍒", "树脂3D打印切片软件插件，支持智能支撑、镂空挖孔、LYS导出", &["模型导入","树脂切片","支撑编辑","镂空挖孔","导出LYS"], &["stl","obj","lys","ctb"]),
]);

#[cfg(test)]
const CATEGORIES: [&str; 6] = ["web", "ad", "industrial", "threeD", "arch", "interior"];

/// 全量注册表 JSON（Dart 侧 PluginManager 的运行时权威源）。
pub fn get_builtin_plugins() -> String {
    serde_json::to_string(&*PLUGINS).unwrap_or_else(|_| "[]".into())
}

/// 单个插件的能力 JSON；未命中返回 "{}"。
pub fn get_plugin_capabilities(plugin_id: &str) -> String {
    PLUGINS
        .iter()
        .find(|p| p.id == plugin_id)
        .map(|p| {
            serde_json::json!({
                "actions": p.capabilities.actions,
                "file_formats": p.capabilities.file_formats,
            })
            .to_string()
        })
        .unwrap_or_else(|| "{}".into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_has_plugins_with_unique_ids() {
        assert!(PLUGINS.len() >= 60, "registry shrank unexpectedly");
        let mut ids: Vec<&str> = PLUGINS.iter().map(|p| p.id).collect();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(ids.len(), PLUGINS.len(), "plugin ids must be unique");
    }

    #[test]
    fn required_fields_non_empty_and_category_valid() {
        for p in PLUGINS.iter() {
            assert!(!p.id.is_empty() && !p.name.is_empty(), "id/name required");
            assert!(CATEGORIES.contains(&p.category), "invalid category for {}", p.id);
            assert!(!p.script_language.is_empty(), "script_language required for {}", p.id);
            assert!(!p.icon.is_empty(), "icon required for {}", p.id);
            assert!(!p.description.is_empty(), "description required for {}", p.id);
            assert!(!p.capabilities.actions.is_empty(), "actions required for {}", p.id);
            assert!(!p.capabilities.file_formats.is_empty(), "file_formats required for {}", p.id);
        }
    }

    #[test]
    fn capabilities_lookup_hits_and_misses() {
        let hit = serde_json::from_str::<serde_json::Value>(&get_plugin_capabilities("figma")).unwrap();
        assert_eq!(hit["actions"][0], "创建画布");
        assert_eq!(hit["file_formats"][0], "fig");
        assert_eq!(get_plugin_capabilities("nonexistent"), "{}");
    }

    #[test]
    fn serialized_json_has_expected_shape() {
        let value: serde_json::Value = serde_json::from_str(&get_builtin_plugins()).unwrap();
        let array = value.as_array().unwrap();
        assert!(array.len() >= 60, "registry shrank unexpectedly");
        let first = &array[0];
        assert_eq!(first["id"], "figma");
        assert!(first["script_language"].is_string());
        assert!(first["capabilities"]["actions"].is_array());
    }

    #[test]
    fn every_workspace_plugin_crate_is_registered() {
        // Workspace members are the source of truth for which plugin crates
        // exist; a new crate without a registry entry breaks Dart-side
        // discovery. Adobe CC crates are Dart-stub only (see workspace
        // Cargo.toml comments), so this direction is one-way on purpose.
        let workspace_toml = include_str!("../../Cargo.toml");
        let members_line = workspace_toml
            .lines()
            .find(|l| l.trim_start().starts_with("members"))
            .expect("workspace members line");
        let registered: Vec<&str> = PLUGINS.iter().map(|p| p.id).collect();
        for tok in members_line.split('"') {
            if let Some(id) = tok.strip_prefix("plugins/") {
                assert!(
                    registered.contains(&id),
                    "workspace plugin crate `{id}` is missing from the registry"
                );
            }
        }
    }

    #[test]
    fn registry_ids_and_formats_are_clean() {
        for p in PLUGINS.iter() {
            assert!(
                p.id.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit()),
                "registry id `{}` must be lowercase alphanumeric",
                p.id
            );
            assert!(
                p.capabilities
                    .file_formats
                    .iter()
                    .all(|f| !f.is_empty() && !f.chars().any(|c| c.is_whitespace() || c.is_control())),
                "illegal file format in `{}`",
                p.id
            );
        }
    }
}
