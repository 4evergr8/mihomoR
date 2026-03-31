import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:yaml/yaml.dart';

// 递归将 YamlMap/YamlList 转为普通 Map/List
dynamic _convertYaml(dynamic input) {
  if (input is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      input.entries.map(
            (e) => MapEntry(e.key.toString(), _convertYaml(e.value)),
      ),
    );
  } else if (input is YamlList) {
    return input.map((e) => _convertYaml(e)).toList();
  } else {
    return input;
  }
}

Future<Map<String, dynamic>> readYamlAsObject(String sourcePath) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = p.join(dir.path, p.basename(sourcePath));

    final result = await Process.run(
      'su',
      ['-c', 'cp $sourcePath $localPath && chmod 777 $localPath'],
    );

    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }

    final text = await File(localPath).readAsString();
    final obj = yamlDecode(text);

    return _convertYaml(obj) as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

Future<void> writeYamlFromObject(
    Map<String, dynamic> data,
    String targetPath,
    ) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = p.join(dir.path, p.basename(targetPath));

    final yamlText = yamlEncode(data);

    final file = File(localPath);
    await file.writeAsString(yamlText);

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