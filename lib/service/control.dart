import 'dart:io';

import 'package:clashroot/service/path.dart';
import 'package:quick_settings_with_flutter_plugins/quick_settings.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Process.run("su", ["-c","busybox", "sh", scriptPath, "loop"]);
    return Future.value(true);
  });
}

Future<String> clashKill() async {
  final result = await Process.run("su", ["-c", "busybox","sh", scriptPath, "kill"]);

  final code = result.exitCode;
  final output = result.stdout.toString();
  final error = result.stderr.toString();

  if (code != 0) {
    throw Exception("FAIL\n$output\n$error");
  }
  await Workmanager().cancelAll();
  await QuickSettings.syncTile(
    Tile(
      label: "ClashRoot",
      tileStatus: TileStatus.inactive,
      drawableName: 'alarm_off',
      contentDescription: "Clash核心已停止",
    ),
  );
  return "OK\n$output";
}

Future<String> clashStart() async {
  final result = await Process.run("su", ["-c", "busybox", "sh", scriptPath, "start"]);

  final code = result.exitCode;
  final output = result.stdout.toString();
  final error = result.stderr.toString();

  if (code != 0) {
    Workmanager().cancelAll();
    throw Exception("FAIL\n$output\n$error");
  }
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask("clash_loop", "循环任务", frequency: Duration(minutes:20));
  await QuickSettings.syncTile(
    Tile(
      label: "ClashRoot",
      tileStatus: TileStatus.active,
      drawableName: 'alarm_on',
      contentDescription: "Clash核心已启动",
    ),
  );
  return "OK\n$output";
}

Future<String> clashTest() async {
  final result = await Process.run("su", ["-c", "busybox","sh", scriptPath, "test"]);

  final code = result.exitCode;
  final output = result.stdout.toString();
  final error = result.stderr.toString();

  return "code=$code\n$output\n$error".trim();
}

Future<String> clashCheck() async {
  final result = await Process.run("su", ["-c","busybox", "sh", scriptPath, "check"]);

  final code = result.exitCode;
  final output = result.stdout.toString();
  final error = result.stderr.toString();

  return "code=$code\n$output\n$error".trim();
}
