import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:dart_eval/dart_eval.dart';


// 读取 YAML 文件为普通 Map
Future<Map<String, dynamic>> readYamlAsObject(String sourcePath) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = join(dir.path, basename(sourcePath));

    final result = await Process.run(
      'su',
      ['-c', 'cp $sourcePath $localPath && chmod 777 $localPath'],
    );

    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }

    final text = await File(localPath).readAsString();
    final obj = YamlCodec().decode(text);

    return obj as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

// 将 Map 写回 YAML 文件
Future<void> writeYamlFromObject(Map<String, dynamic> data, String targetPath) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = join(dir.path, basename(targetPath));

    final yamlText = YamlCodec().encode(data);
    await File(localPath).writeAsString(yamlText);

    final result = await Process.run(
      'su',
      ['-c', 'cp $localPath $targetPath && chmod 777 $targetPath'],
    );

    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> runUserDartFromFile(
    Map<String, dynamic> config, String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final localPath = join(dir.path, basename(sourcePath));

  // 拷贝文件到可读写目录
  final result = await Process.run(
    'su',
    ['-c', 'cp $sourcePath $localPath && chmod 777 $localPath'],
  );
  if (result.exitCode != 0) throw Exception(result.stderr);

  // 读取 Dart 文件内容
  final userCode = await File(localPath).readAsString();

  // 执行用户 Dart，用户代码必须定义 main(config) 返回修改后的 Map
  final modified = eval(
    userCode,
    function: 'main',
    args: [config],
  );

  return modified as Map<String, dynamic>;
}