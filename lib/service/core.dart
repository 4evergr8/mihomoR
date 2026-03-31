import 'dart:io';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/yaml.dart';

Future<void> stopMihomo() async {
  final settings = await readYamlAsObject(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }
}

Future<void> startMihomo() async {
  try {
    final settings = await readYamlAsObject(settingsPath);
    final stopCmd = settings['kill'] ?? '';
    final startCmd = settings['start'] ?? '';

    // 先停止
    if (stopCmd.isNotEmpty) {
      await Process.run("sh", ["-c", stopCmd]);
    }

    // 再启动
    if (startCmd.isNotEmpty) {
      await Process.start("sh", ["-c", startCmd]);
    }
  } catch (_) {}
}