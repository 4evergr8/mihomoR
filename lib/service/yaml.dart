import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:yaml/yaml.dart';
import 'package:dart_eval/dart_eval.dart';

/// 递归转换 YAML → Dart 原生结构
dynamic _convertYaml(dynamic node) {
  if (node is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      node.entries.map(
            (e) => MapEntry(e.key.toString(), _convertYaml(e.value)),
      ),
    );
  } else if (node is YamlList) {
    return node.map(_convertYaml).toList();
  }
  return node;
}

/// 读取 YAML 文件为动态对象（已转标准结构）
Future<dynamic> readYamlAsObject(String sourcePath) async {
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

  return _convertYaml(obj); // ✅ 关键
}

/// 将动态对象写回 YAML 文件
Future<void> writeYamlFromObject(dynamic data, String targetPath) async {
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
}

/// 执行用户 Dart 文件（已保证输入输出稳定）
Future<dynamic> runUserDartFromFile(dynamic config, String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final localPath = join(dir.path, basename(sourcePath));

  final result = await Process.run(
    'su',
    ['-c', 'cp $sourcePath $localPath && chmod 777 $localPath'],
  );
  if (result.exitCode != 0) throw Exception(result.stderr);

  final userCode = await File(localPath).readAsString();

  final modified = eval(
    userCode,
    function: 'override',
    args: [config],
  );
  return modified;
}