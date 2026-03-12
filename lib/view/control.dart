import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/yaml.dart';
import 'package:dart_ping/dart_ping.dart';

class ControlView extends StatefulWidget {
  const ControlView({super.key});

  @override
  State<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends State<ControlView> {
  List<String> delays = ["--", "--", "--"];
  final String settingsPath = '/data/adb/mihomo/settings.yaml';

  @override
  void initState() {
    super.initState();
    testDelays();
  }

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
    final hosts = ["www.google.com", "github.com", "t.me"];
    final futures = hosts.map((host) async {
      try {
        final ping = Ping(host, count: 1);
        await for (final event in ping.stream) {
          final r = event.response;
          if (r != null) return r.time?.inMilliseconds.toString() ?? "超时";
        }
        return "超时";
      } catch (_) {
        return "超时";
      }
    });
    final results = await Future.wait(futures);
    setState(() {
      delays = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 第一块：测速，二级颜色
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Google', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[0], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Github', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[1], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Telegram', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[2], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: testDelays,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 第二块：四个按钮，一级颜色
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('启动', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: kill,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: openWeb,
                            icon: const Icon(Icons.language),
                            label: const Text('WEBUI', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: reloadConfig,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重载配置', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}