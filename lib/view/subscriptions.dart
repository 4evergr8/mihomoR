import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yaml_codec/yaml_codec.dart';
import '../service/subscriptions.dart';
import '../service/yaml.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  List<SubscriptionInfo> subscriptions = [];
  bool isLoading = true;
  final String yamlPath = '/data/adb/mihomo/subscriptions.yaml';
  final YamlCodec yamlCodec = const YamlCodec();

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  /// 读取 YAML 加载订阅
  Future<void> _loadSubscriptions() async {
    try {
      final f = File(yamlPath);
      if (!await f.exists()) {
        subscriptions = [];
      } else {
        final text = await f.readAsString();
        final data = yamlCodec.decode(text);
        final list = (data is Map && data['subscriptions'] is List)
            ? (data['subscriptions'] as List)
            : [];
        subscriptions = list
            .map((e) => SubscriptionInfo.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      setState(() => isLoading = false);
    } catch (_) {
      subscriptions = [];
      setState(() => isLoading = false);
    }
  }

  /// 保存订阅到 YAML
  Future<void> _saveSubscriptions() async {
    try {
      final data = {
        'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
      };
      final yamlText = yamlCodec.encode(data);

      final f = File(yamlPath);
      if (!await f.exists()) await f.create(recursive: true);
      await f.writeAsString(yamlText);

      // 用 root 设置权限
      final result = await Process.run(
        'su',
        ['-c', 'chmod 600 $yamlPath'],
      );
      if (result.exitCode != 0) throw Exception(result.stderr);
    } catch (e) {
      rethrow;
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('确认')),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final settings=await readYamlAsObject("/data/adb/mihono/settings.yaml");
      final ua = settings['ua'];
      final downloadResult = await downloadYamlFile(result,ua);

      subscriptions.add(SubscriptionInfo(
        id: downloadResult.id,
        label: downloadResult.label,
        uploaded: downloadResult.upload,
        downloaded: downloadResult.download,
        total: downloadResult.total,
        expireDate: DateTime.fromMillisecondsSinceEpoch(downloadResult.expire * 1000),
      ));

      await _saveSubscriptions();
      setState(() {});
    } catch (e) {
      rethrow;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// 删除订阅
  Future<void> _deleteSubscription(String id) async {
    subscriptions.removeWhere((s) => s.id == id);
    await _saveSubscriptions();
    setState(() {});
  }

  /// 编辑订阅
  Future<void> _editSubscription(String id) async {
    final sub = subscriptions.firstWhere((s) => s.id == id);
    final controller = TextEditingController(text: sub.label);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改订阅'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入新的订阅名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('确认')),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    sub.label = result;
    await _saveSubscriptions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscriptions.isEmpty
          ? const Center(child: Text('暂无订阅'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final sub = subscriptions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('订阅 ${sub.label}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade300,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: sub.uploaded,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: sub.downloaded,
                          child: Container(color: Theme.of(context).colorScheme.secondary),
                        ),
                        Expanded(
                          flex: sub.total - sub.uploaded - sub.downloaded,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '上传: ${sub.uploaded}GB  下载: ${sub.downloaded}GB  剩余: ${sub.total - sub.uploaded - sub.downloaded}GB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '到期时间: ${sub.expireDate.year}-${sub.expireDate.month}-${sub.expireDate.day}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.delete_outlined, size: 20), onPressed: () => _deleteSubscription(sub.id)),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editSubscription(sub.id)),
                    ],
                  ),
                ],
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