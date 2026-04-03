import 'dart:io';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/subscriptions.dart';

Future<void> stopMihomo() async {
  final settings = await readYamlAsMap(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }
}

Future<void> startMihomo() async {
  final settings = await readYamlAsMap(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  final startCmd = settings['start'] ?? '';

  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }
  if (startCmd.isNotEmpty) {
    await Process.start("sh", ["-c", startCmd]);
  }

}
