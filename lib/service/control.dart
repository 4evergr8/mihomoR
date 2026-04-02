import 'dart:io';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/subscriptions.dart';
import 'package:quick_settings_with_flutter_plugins/quick_settings.dart';

Future<void> stopMihomo() async {
  await QuickSettings.syncTile(
    Tile(
      label: "mihomo",
      tileStatus: TileStatus.inactive,
      drawableName: 'quick_settings_base_icon',
      contentDescription: "mihomo 已停止",
    ),
  );
  final settings = await readYamlAsMap(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }

}

Future<void> startMihomo() async {
  await QuickSettings.syncTile(
    Tile(
      label: "mihomo",
      tileStatus: TileStatus.active,
      drawableName: 'quick_settings_base_icon',
      contentDescription: "mihomo 已启动",
    ),
  );
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

}
