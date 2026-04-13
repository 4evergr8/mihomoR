import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/subscriptions.dart';
import 'package:mihomoR/widget.dart';

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

class _ProxiesViewState extends State<ProxiesView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // 不保持状态
  List<DelayItem> delayList = [];
  bool isTesting = false;
  int successCount = 0;
  int totalCount = 0;
  int timeout = 0;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testDelay();
    });
  }

  Future<void> _testDelay() async {
    final close = await showLoadingDialogGlobal();
    setState(() => isTesting = true);
    try {
      final config = await readYamlAsMap(configPath);
      final groups = config['proxy-groups'] as List? ?? [];
      final firstGroupName = groups.isNotEmpty ? groups.first['name'] as String? : null;
      final settings = await readYamlAsMap(settingsPath);
      final port = settings['port'];
      final url = settings['url'];
      timeout = settings['testtimeout'];
      final uri = Uri.parse('http://127.0.0.1:$port/group/$firstGroupName/delay?url=$url&timeout=$timeout');
      final req = await HttpClient().getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final Map<String, dynamic> data = json.decode(body);
      if (data.containsKey('message')) {
        message = data['message'] as String?;
        delayList = [];
        totalCount = 0;
        successCount = 0;
      } else {
        message = null;
        final list =
            data.entries.map((e) {
              return DelayItem(e.key, (e.value ?? 0) as int);
            }).toList();
        totalCount = list.length;
        successCount = list.where((e) => e.delay <= timeout).length;
        list.sort((a, b) => a.delay.compareTo(b.delay));
        delayList = list;
        // ===== 写入 YAML 的 count =====
        try {
          final data = await readYamlAsMap(subscriptionsPath);
          final subs = (data['subscriptions'] is List) ? List<Map<String, dynamic>>.from(data['subscriptions']) : <Map<String, dynamic>>[];

          final settings = await readYamlAsMap(settingsPath);
          final selectedId = settings['selected'];

          for (final sub in subs) {
            if (sub['id'] == selectedId) {
              sub['count'] = successCount;
              break;
            }
          }

          await writeYamlFromMap({'subscriptions': subs}, subscriptionsPath);
        } catch (_) {}
      }
      setState(() {});
    } catch (e) {
      showErrorSnackBarGlobal('$e');
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
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('节点')),
      body:
          isTesting && delayList.isEmpty && message == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _testDelay,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (message != null)
                      Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(message!, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold))))
                    else ...[
                      // 可用率
                      Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: ListTile(title: const Text('节点可用率'), subtitle: totalCount == 0 ? const Text('暂无可用节点') : Text('$successCount / $totalCount'), trailing: Text(totalCount == 0 ? '--' : '${(successCount * 100 ~/ totalCount)}%', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)))),

                      // 节点列表
                      ...delayList.map((item) {
                        final color = _getColor(context, item.delay);
                        final isAlive = item.delay <= timeout;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          color: colorScheme.surface,
                          child: ListTile(title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(_formatDelay(item.delay)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_formatDelay(item.delay), style: TextStyle(color: color, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(Icons.circle, size: 10, color: isAlive ? color : colorScheme.error)])),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(onPressed: isTesting ? null : _testDelay, child: const Icon(Icons.speed)),
    );
  }
}
