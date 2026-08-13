import 'dart:io';

/// 软件脚本执行配置：LocalScriptExecutor 依据此注册表决定如何调用 CLI
/// 执行生成的脚本。新增软件只需在此加一条，无需改执行器逻辑。
class ScriptExecutorConfig {
  final String pluginId;
  final String executable;

  /// 生成的脚本文件扩展名（不含点）。
  final String scriptExtension;

  /// 构建 CLI 参数。scriptPath 为已写好的脚本文件，tempDir 为本次执行
  /// 的临时目录（部分软件需额外生成加载器文件，如 AutoCAD 的 .scr）。
  final List<String> Function(String scriptPath, Directory tempDir) args;

  /// 可用性探测参数，默认 --version。
  final List<String> probeArgs;

  /// 仅支持的平台，null 表示全平台。
  final Set<String>? platforms;

  const ScriptExecutorConfig({
    required this.pluginId,
    required this.executable,
    required this.scriptExtension,
    required this.args,
    this.probeArgs = const ['--version'],
    this.platforms,
  });

  bool supportsPlatform(String os) => platforms == null || platforms!.contains(os);
}

/// 默认注册表：Blender/FreeCAD/OpenSCAD 为既有能力，其余为本次新增。
List<ScriptExecutorConfig> defaultExecutorConfigs() => [
      ScriptExecutorConfig(
        pluginId: 'blender',
        executable: 'blender',
        scriptExtension: 'py',
        args: (scriptPath, _) => ['--background', '--python', scriptPath],
      ),
      ScriptExecutorConfig(
        pluginId: 'freecad',
        executable: 'freecad',
        scriptExtension: 'py',
        args: (scriptPath, _) => [
          '-c',
          'import os; exec(open(os.environ["AI_DESIGN_SCRIPT"], encoding="utf-8").read())',
        ],
      ),
      ScriptExecutorConfig(
        pluginId: 'openscad',
        executable: 'openscad',
        scriptExtension: 'scad',
        args: (scriptPath, tempDir) => ['-o', '${tempDir.path}/out.stl', scriptPath],
      ),
      // AutoCAD：accoreconsole 无头控制台，/b 执行 .scr；scr 内 (load) 注入 AutoLISP。
      ScriptExecutorConfig(
        pluginId: 'autocad',
        executable: 'accoreconsole',
        scriptExtension: 'lsp',
        platforms: {'windows'},
        probeArgs: const ['/?'],
        args: (scriptPath, tempDir) {
          final loader = File('${tempDir.path}/run.scr');
          loader.writeAsStringSync('(load "${scriptPath.replaceAll('\\', '/')}")\nquit\n');
          return ['/b', loader.path];
        },
      ),
      ScriptExecutorConfig(
        pluginId: 'rhino',
        executable: 'rhino',
        scriptExtension: 'py',
        args: (scriptPath, _) => ['-runscript', scriptPath],
      ),
      ScriptExecutorConfig(
        pluginId: 'photoshop',
        executable: 'photoshop',
        scriptExtension: 'jsx',
        args: (scriptPath, _) => [scriptPath],
      ),
      ScriptExecutorConfig(
        pluginId: 'illustrator',
        executable: 'illustrator',
        scriptExtension: 'jsx',
        args: (scriptPath, _) => [scriptPath],
      ),
      ScriptExecutorConfig(
        pluginId: 'fusion360',
        executable: 'fusion360',
        scriptExtension: 'py',
        args: (scriptPath, _) => ['-p', scriptPath],
      ),
      ScriptExecutorConfig(
        pluginId: 'sketchup',
        executable: 'sketchup',
        scriptExtension: 'rb',
        args: (scriptPath, _) => ['-RubyStartup', scriptPath],
      ),
      // Sketch：sketchtool 是真 headless；仅 macOS。
      ScriptExecutorConfig(
        pluginId: 'sketch',
        executable: 'sketchtool',
        scriptExtension: 'js',
        platforms: {'macos'},
        args: (scriptPath, _) => ['run', scriptPath],
      ),
    ];
