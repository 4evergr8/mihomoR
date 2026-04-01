import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:yaml/yaml.dart';


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
/// 读取 YAML 文件为 Map，顶层必须是 Map，否则报错
Future<Map<String, dynamic>> readYamlAsMap(String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final localPath = join(dir.path, basename(sourcePath));

  final result = await Process.run(
    'su',
    ['-c', 'cp $sourcePath $localPath && chmod 777 $localPath'],
  );
  if (result.exitCode != 0) throw Exception(result.stderr);

  final text = await File(localPath).readAsString();
  final obj = YamlCodec().decode(text);

  final converted = _convertYaml(obj);
  if (converted is! Map<String, dynamic>) {
    throw Exception('YAML 顶层不是 Map，无法处理: $sourcePath');
  }
  return converted;
}

/// 写 Map 回 YAML 文件
Future<void> writeYamlFromMap(Map<String, dynamic> data, String targetPath) async {
  final dir = await getApplicationDocumentsDirectory();
  final localPath = join(dir.path, basename(targetPath));

  final yamlText = YamlCodec().encode(data);
  await File(localPath).writeAsString(yamlText);

  final result = await Process.run(
    'su',
    ['-c', 'cp $localPath $targetPath && chmod 777 $targetPath'],
  );
  if (result.exitCode != 0) throw Exception(result.stderr);
}

/// 顶层覆盖 Map：patch 的值覆盖 base 的同名 key
Map<String, dynamic> overrideMap(Map<String, dynamic> base, Map<String, dynamic> override) {
  final result = Map<String, dynamic>.from(base); // 拷贝一份 base
  override.forEach((key, value) {
    result[key] = value; // 顶层覆盖
  });
  return result;
}