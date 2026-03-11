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
  List<String> delays = ["--", "--", "--"];

  Future<void> start() async {
    final settings = await readYamlAsObject("/data/adb/mihono/settings.yaml");
    final start = settings['start'];
    await Process.start("sh", ["-c", start]);
  }

  Future<void> kill() async {
    final settings = await readYamlAsObject("/data/adb/mihono/settings.yaml");
    final kill = settings['kill'];
    await Process.start("sh", ["-c", kill]);
  }

  Future<void> openWeb() async {
    final settings = await readYamlAsObject("/data/adb/mihono/settings.yaml");
    final port = settings['port'];
    final uri = Uri.parse("http://127.0.0.1:$port");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> reloadConfig() async {
    final settings = await readYamlAsObject("/data/adb/mihono/settings.yaml");
    final dio = Dio();
    final port = settings['port'];
    await dio.put('http://127.0.0.1:$port/configs?force=true');
  }

  /// 顺序测试三个延迟,超时2秒
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
      try {
        final sw = Stopwatch()..start();
        await dio.get(urls[i]);
        sw.stop();
        results.add(sw.elapsedMilliseconds.toString());
      } catch (_) {
        // 超时或请求失败,后面全部标记超时
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

  Widget delayCard(String title, String delay, VoidCallback onRefresh) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(delay, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: onRefresh),
            )
          ],
        ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Row(
              children: [
                delayCard('Google', delays[0], testDelays),
                const SizedBox(width: 12),
                delayCard('Github', delays[1], testDelays),
                const SizedBox(width: 12),
                delayCard('Telegram', delays[2], testDelays),
              ],
            ),
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