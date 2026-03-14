import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quick_settings/quick_settings.dart';
import '../theme/theme.dart';
import '../theme/util.dart';
import '../widget.dart';
import '../service/yaml.dart';

const String settingsPath = '/data/adb/mihomo/settings.yaml';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  QuickSettings.listen((event) async {
    try {
      final settings = await readYamlAsObject(settingsPath);

      final stopCmd = settings['kill'] ?? '';
      final startCmd = settings['start'] ?? '';

      await Process.run("sh", ["-c", stopCmd]);
      await Process.start("sh", ["-c", startCmd]);

    } catch (_) {}
  });

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

    QuickSettings.addTileToQuickSettings(
      label: "重启mihomo",
      drawableName: "quick_settings_base_icon",
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar();
  }
}