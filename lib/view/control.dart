import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/yaml.dart';

class ControlView extends StatefulWidget {
  const ControlView({super.key});

  @override
  State<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends State<ControlView> {
  @override
  void initState() {
    super.initState();
    testDelays(); // 页面进入时自动检测延迟
  }

  List<String> delays = ["--", "--", "--"];
  final String settingsPath = '/data/adb/mihomo/settings.yaml';

  Future<void> start() async {
    final settings = await readYamlAsObject(settingsPath);
    final start = settings['start'];
    await Process.start("sh", ["-c", start]);
  }

  Future<void> kill() async {
    final settings = await readYamlAsObject(settingsPath);
    final kill = settings['kill'];
    await Process.start("sh", ["-c", kill]);
  }

  Future<void> openWeb() async {
    final settings = await readYamlAsObject(settingsPath);
    final port = settings['port'];
    final uri = Uri.parse("http://127.0.0.1:$port/ui");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> reloadConfig() async {
    final settings = await readYamlAsObject(settingsPath);
    final dio = Dio();
    final port = settings['port'];
    await dio.put('http://127.0.0.1:$port/configs?force=true');
  }

  Future<void> testDelays() async {
    final urls = [
      "https://www.google.com",
      "https://github.com",
      "https://t.me"
    ];

    List<String> results = [];
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ));

    for (int i = 0; i < urls.length; i++) {
      final sw = Stopwatch()..start();
      try {
        await dio.get(urls[i]);
        sw.stop();
        results.add(sw.elapsedMilliseconds.toString());
      } catch (_) {
        sw.stop();
        results.add("超时");
        for (int j = i + 1; j < urls.length; j++) {
          results.add("超时");
        }
        break;
      }
    }

    setState(() {
      delays = results;
    });
  }

  Widget delayCardGroup(VoidCallback onRefresh) {

    Widget item(String title, String delay) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(delay, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surface, // 卡片背景跟主题
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Row(
              children: [
                item('Google', delays[0]),
                item('Github', delays[1]),
                item('Telegram', delays[2]),
              ],
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              color: Theme.of(context).colorScheme.primary, // 图标使用主题主色
              onPressed: onRefresh,
            ),
          )
        ],
      ),
    );
  }

  Widget bigButton(String text, VoidCallback onPressed, Color color) {


    return Expanded(
      child: SizedBox(
        height: 70,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: color == Theme.of(context).colorScheme.primary
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(text, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget smallButton(String text, VoidCallback onPressed) {


    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary, // 背景跟主题
            foregroundColor: Theme.of(context).colorScheme.onPrimary, // 字体跟主题
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                bigButton('启动', start, Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                bigButton('停止', kill, Theme.of(context).colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 20),
            delayCardGroup(testDelays),
            const SizedBox(height: 20),
            Row(
              children: [
                smallButton('打开网页', openWeb),
                const SizedBox(width: 16),
                smallButton('重载配置', reloadConfig),
              ],
            ),
          ],
        ),
      ),
    );
  }
}