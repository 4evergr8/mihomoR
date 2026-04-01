import 'dart:io';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/yaml.dart';
import 'package:quick_settings_with_flutter_plugins/quick_settings.dart';

Future<void> stopMihomo() async {
  final settings = await readYamlAsMap(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }
  await QuickSettings.syncTile(
    Tile(
      label: "mihomo",
      tileStatus: TileStatus.inactive,
      drawableName: 'quick_settings_base_icon',
      contentDescription: "mihomo 已停止",
    ),
  );
}

Future<void> startMihomo() async {
  final settings = await readYamlAsMap(settingsPath);
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
  await QuickSettings.syncTile(
    Tile(
      label: "mihomo",
      tileStatus: TileStatus.active,
      drawableName: 'quick_settings_base_icon',
      contentDescription: "mihomo 已启动",
    ),
  );
}
