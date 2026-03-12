import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../service/sub.dart';
import '../service/yaml.dart';
import '../widget.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  List<SubscriptionInfo> subscriptions = [];
  bool isLoading = true;
  String? selectedId; // 当前被选中的订阅 ID

  final String subscriptionsPath = '/data/adb/mihomo/subscriptions.yaml';
  final String settingsPath = '/data/adb/mihomo/settings.yaml';
  final String rewritePath = '/data/adb/mihomo/rewrite.yaml';
  final String configPath = '/data/adb/mihomo/config.yaml';

  String formatGB(int bytes) => (bytes / 1024 / 1024 / 1024).toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  /// 点击订阅
  Future<void> _onSubscriptionTap(String id) async {
    final close = await showLoadingDialog(context, title: '加载中...');
    try {
      final base = await readYamlAsObject("/data/adb/mihomo/$id.yaml");
      final patch = await readYamlAsObject(rewritePath);
      final yaml = overwriteYamlObject(base, patch);
      await writeYamlFromObject(yaml, configPath);
      final settings = await readYamlAsObject(settingsPath);
      final dio = Dio();
      final params = {'force': 'true'};
      final data = {"path": "", "payload": ""};
      final port = settings['port'];
      try{ await dio.put(
        'http://127.0.0.1:$port/configs',
        queryParameters: params,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );}catch(e){}
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      close();
    }
  }

  /// 刷新订阅
  Future<void> _refreshSubscriptions() async {
    setState(() => isLoading = true);
    if (!mounted) return;
    final close = await showLoadingDialog(context, title: '加载中...');
    try {
      final data = await readYamlAsObject(subscriptionsPath);
      final list =
          (data['subscriptions'] is List)
              ? (data['subscriptions'] as List)
              : [];

      List<SubscriptionInfo> updatedSubs = [];
      for (var e in list) {
        final sub = SubscriptionInfo.fromMap(Map<String, dynamic>.from(e));
        try {
          final settings = await readYamlAsObject(settingsPath);
          final ua = settings['ua'];
          final downloadResult = await downloadYamlFile(sub.link, ua, sub.id);
          updatedSubs.add(
            SubscriptionInfo(
              id: downloadResult.id,
              link: downloadResult.link,
              label: downloadResult.label,
              upload: downloadResult.upload,
              download: downloadResult.download,
              total: downloadResult.total,
              expire: downloadResult.expire,
            ),
          );

        } catch (e) {


          updatedSubs.add(sub);
        }
      }

      final newData = {
        'subscriptions': updatedSubs.map((s) => s.toMap()).toList(),
      };
      await writeYamlFromObject(newData, subscriptionsPath);

      setState(() => subscriptions = updatedSubs);
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      close();
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 读取 YAML 加载订阅
  Future<void> _loadSubscriptions() async {
    try {
      final data = await readYamlAsObject(subscriptionsPath);
      final list =
          (data['subscriptions'] is List)
              ? (data['subscriptions'] as List)
              : [];

      subscriptions =
          list
              .map(
                (e) => SubscriptionInfo.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList();

      final settings = await readYamlAsObject(settingsPath);
      selectedId = settings['selected'] as String?;
    } catch (e) {
      subscriptions = [];
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 删除指定订阅
  Future<void> _deleteSubscription(
    BuildContext context,
    SubscriptionInfo sub,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定删除订阅 "${sub.label}" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认'),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final close = await showLoadingDialog(context, title: '删除中...');
    try {
      subscriptions.removeWhere((s) => s.id == sub.id);
      final data = {
        'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
      };
      await writeYamlFromObject(data, subscriptionsPath);
      await Process.run('su', ['-c', 'rm -f /data/adb/mihomo/${sub.id}.yaml']);
      if (selectedId == sub.id) {
        selectedId = null;
        final settings = await readYamlAsObject(settingsPath);
        settings['selected'] = null;
        await writeYamlFromObject(settings, settingsPath);
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '删除失败', e);
    } finally {
      if (mounted) close();
    }
  }

  /// 添加订阅
  Future<void> _addSubscription() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加订阅'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入订阅地址'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    final close = await showLoadingDialog(context, title: '加载中...');
    try {
      final settings = await readYamlAsObject(settingsPath);
      final ua = settings['ua'];
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final downloadResult = await downloadYamlFile(result, ua, id);

      subscriptions.add(
        SubscriptionInfo(
          id: downloadResult.id,
          link: downloadResult.link,
          label: downloadResult.label,
          upload: downloadResult.upload,
          download: downloadResult.download,
          total: downloadResult.total,
          expire: downloadResult.expire,
        ),
      );
      final data = {
        'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
      };
      await writeYamlFromObject(data, subscriptionsPath);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      if (mounted) close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSubscriptions,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : subscriptions.isEmpty
              ? const Center(child: Text('暂无订阅'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  final totalValue = sub.total;

                  int scale(int value) {
                    if (totalValue == 0) return 0;
                    final v = value * 100 ~/ totalValue;
                    return v.clamp(0, 100);
                  }
                  final isSelected = sub.id == selectedId;

                  return InkWell(
                    onTap: () async {
                      setState(() => selectedId = sub.id);
                      final settings = await readYamlAsObject(settingsPath);
                      settings['selected'] = sub.id;
                      await writeYamlFromObject(settings, settingsPath);

                      await _onSubscriptionTap(sub.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          height: 12,
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          child: Row(
                                            children: [
                                              if (sub.upload > 0)
                                                Expanded(
                                                  flex: scale(sub.upload),
                                                  child: Container(
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              if (sub.download > 0)
                                                Expanded(
                                                  flex: scale(sub.download),
                                                  child: Container(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                ),
                                              Expanded(
                                                flex: (100 - scale(sub.upload) - scale(sub.download))
                                                    .clamp(0, 100),
                                                child: Container(
                                                  color: Theme.of(context).colorScheme.surface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        sub.total == 0
                                            ? '上传: ∞  下载: ∞  总量: ∞'
                                            : '上传: ${formatGB(sub.upload)}GB  下载: ${formatGB(sub.download)}GB  总量: ${formatGB(sub.total)}GB',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sub.expire == 0
                                            ? '到期时间: ∞'
                                            : '到期时间: ${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).year}-'
                                            '${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).month}-'
                                            '${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).day}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _deleteSubscription(context, sub),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubscription,
        child: const Icon(Icons.add),
      ),
    );
  }
}
