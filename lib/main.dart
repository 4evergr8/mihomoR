import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quick_settings/quick_settings.dart';
import '../theme/theme.dart';
import '../theme/util.dart';
import '../widget.dart';
import '../service/yaml.dart';

const String settingsPath = '/data/adb/mihomo/settings.yaml';

/// Tile 点击回调
@pragma('vm:entry-point')
Tile onTileClicked(Tile tile) {
  _restartMihomo();
  return tile; // 返回 tile
}

/// Tile 添加回调
@pragma('vm:entry-point')
Tile? onTileAdded(Tile tile) => tile;

/// Tile 移除回调
@pragma('vm:entry-point')
void onTileRemoved() {}

/// 执行重启 mihomo
void _restartMihomo() async {
  try {
    final settings = await readYamlAsObject(settingsPath);
    final stopCmd = settings['kill'] ?? '';
    final startCmd = settings['start'] ?? '';

    if (stopCmd.isNotEmpty) await Process.run("sh", ["-c", stopCmd]);
    if (startCmd.isNotEmpty) await Process.start("sh", ["-c", startCmd]);
  } catch (_) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册 Quick Settings Tile 回调
  QuickSettings.setup(
    onTileClicked: onTileClicked,
    onTileAdded: onTileAdded,
    onTileRemoved: onTileRemoved,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    TextTheme textTheme = createTextTheme(context, "Noto Sans", "Noto Sans");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'mihomoR',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar();
  }
}