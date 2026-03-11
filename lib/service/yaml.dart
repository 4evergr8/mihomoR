import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml_codec/yaml_codec.dart';

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

    return Map<String, dynamic>.from(obj);
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