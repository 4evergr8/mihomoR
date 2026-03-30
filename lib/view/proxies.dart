import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../service/yaml.dart';
import '../widget.dart';

class ProxiesView extends StatefulWidget {
  const ProxiesView({super.key});

  @override
  State<ProxiesView> createState() => _ProxiesViewState();
}

class DelayItem {
  final String name;
  final int delay;

  DelayItem(this.name, this.delay);
}

class _ProxiesViewState extends State<ProxiesView> {
  List<DelayItem> delayList = [];
  bool isTesting = false;

  final String settingsPath = '/data/adb/mihomo/settings.yaml';
  final String configPath = '/data/adb/mihomo/config.yaml';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testDelay();
    });
  }

  Future<void> _testDelay() async {
    if (!mounted) return;

    final close = await showLoadingDialog(context, title: '加载中...');
    setState(() => isTesting = true);

    try {
      final config = await readYamlAsObject(configPath);
      final groups = config['proxy-groups'] as List? ?? [];
      final firstGroupName =
      groups.isNotEmpty ? groups.first['name'] as String? : null;

      final settings = await readYamlAsObject(settingsPath);
      final port = settings['port'];
      final url = settings['url'];
      final timeout = settings['testtimeout'];

      final uri = Uri.parse(
        'http://127.0.0.1:$port/group/$firstGroupName/delay?url=$url&timeout=$timeout',
      );

      final req = await HttpClient().getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      final Map<String, dynamic> data = json.decode(body);

      final list =
      data.entries.map((e) {
        return DelayItem(e.key, (e.value ?? 0) as int);
      }).toList();

      list.sort((a, b) => a.delay.compareTo(b.delay));

      if (!mounted) return;
      setState(() {
        delayList = list;
      });
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '测速失败', e);
    } finally {
      close();
      if (mounted) setState(() => isTesting = false);
    }
  }

  Color _getColor(BuildContext context, int delay) {
    final colorScheme = Theme.of(context).colorScheme;

    if (delay <= 100) return colorScheme.primary;
    if (delay <= 300) return colorScheme.secondary;
    return colorScheme.error;
  }

  String _formatDelay(int delay) {
    if (delay <= 0) return 'timeout';
    return '$delay ms';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('代理节点延迟')),
      body: isTesting && delayList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : delayList.isEmpty
          ? const Center(child: Text('暂无数据'))
          : RefreshIndicator(
        onRefresh: _testDelay,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: delayList.length,
          itemBuilder: (context, index) {
            final item = delayList[index];
            final color = _getColor(context, item.delay);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: colorScheme.surface,
              child: ListTile(
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatDelay(item.delay)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDelay(item.delay),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: color,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isTesting ? null : _testDelay,
        child: const Icon(Icons.speed),
      ),
    );
  }
}