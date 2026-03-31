import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mihomoR/service/sub.dart';
import 'package:mihomoR/service/yaml.dart';
import 'package:mihomoR/widget.dart';
import 'package:mihomoR/service/path.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持状态
  List<SubscriptionInfo> subscriptions = [];
  bool isLoading = true;
  String? selectedId;

  String formatGB(int bytes) => (bytes / 1024 / 1024 / 1024).toStringAsFixed(1);

  String formatTimeAgo(String timestampMsStr) {
    final pastMs = int.tryParse(timestampMsStr);
    if (pastMs == null) return '时间格式错误';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    int seconds = (nowMs - pastMs) ~/ 1000;

    if (seconds <= 0) return '刚刚';

    const int secsPerMin = 60;
    const int secsPerHour = secsPerMin * 60;
    const int secsPerDay = secsPerHour * 24;
    const int secsPerMonth = secsPerDay * 30;
    const int secsPerYear = secsPerDay * 365;

    final years = seconds ~/ secsPerYear;
    seconds %= secsPerYear;
    final months = seconds ~/ secsPerMonth;
    seconds %= secsPerMonth;
    final days = seconds ~/ secsPerDay;
    seconds %= secsPerDay;
    final hours = seconds ~/ secsPerHour;
    seconds %= secsPerHour;
    final minutes = seconds ~/ secsPerMin;

    final List<String> parts = [];
    if (years > 0) parts.add('$years年');
    if (months > 0) parts.add('$months个月');
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分');

    if (parts.isEmpty) return '刚刚';
    return '${parts.join()}前';
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _onSubscriptionTap(String id) async {
    final close = await showLoadingDialog(context, title: '加载中...');
    try {
      final base = await readYamlAsObject("/data/adb/mihomo/$id.yaml");
      final patch = await readYamlAsObject(rewritePath);
      final yaml = overwriteYamlObject(base, patch);
      await writeYamlFromObject(yaml, configPath);

      try {
        final settings = await readYamlAsObject(settingsPath);
        final dio = Dio();
        final params = {'force': 'true'};
        final data = {"path": "", "payload": ""};
        final port = settings['port'];
        await dio.put(
          'http://127.0.0.1:$port/configs',
          queryParameters: params,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      close();
    }
  }

  Future<void> _refreshSubscriptions() async {
    if (!mounted) return;

    final data = await readYamlAsObject(subscriptionsPath);
    final list =
        (data['subscriptions'] is List) ? (data['subscriptions'] as List) : [];

    final settings = await readYamlAsObject(settingsPath);
    final ua = settings['ua'];
    final timeout = settings['timeout'];

    final futures =
        list.map((e) async {
          final sub = SubscriptionInfo.fromMap(Map<String, dynamic>.from(e));
          try {
            final downloadResult = await downloadYamlFile(
              sub.link,
              ua,
              sub.id,
              timeout,
            );
            return SubscriptionInfo(
              id: downloadResult.id,
              link: downloadResult.link,
              label: downloadResult.label,
              upload: downloadResult.upload,
              download: downloadResult.download,
              total: downloadResult.total,
              expire: downloadResult.expire,
              update: downloadResult.update,
            );
          } catch (_) {
            return sub;
          }
        }).toList();

    final updatedSubs = await Future.wait(futures);
    final newData = {
      'subscriptions': updatedSubs.map((s) => s.toMap()).toList(),
    };
    await writeYamlFromObject(newData, subscriptionsPath);

    if (!mounted) return;
    setState(() => subscriptions = updatedSubs);
  }

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
      subscriptions.sort((a, b) => a.label.compareTo(b.label));

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

  Future<void> _addSubscription() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加订阅'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '每行一个订阅地址',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final text = data?.text;
                if (text != null) {
                  controller.text = text;
                }
              },
              icon: const Icon(Icons.paste),
              label: const Text('粘贴'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, controller.text),
              icon: const Icon(Icons.check),
              label: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;
    if (!mounted) return;

    final close = await showLoadingDialog(context, title: '加载中...');
    try {
      final settings = await readYamlAsObject(settingsPath);
      final ua = settings['ua'];
      final timeout = settings['timeout'];

      final links =
          result
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      for (final link in links) {
        if (subscriptions.any((s) => s.link == link)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('订阅已存在: $link')));
          continue;
        }

        try {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final downloadResult = await downloadYamlFile(link, ua, id, timeout);
          subscriptions.add(
            SubscriptionInfo(
              id: downloadResult.id,
              link: downloadResult.link,
              label: downloadResult.label,
              upload: downloadResult.upload,
              download: downloadResult.download,
              total: downloadResult.total,
              expire: downloadResult.expire,
              update: downloadResult.update,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('下载失败: $link,错误: $e')));
        }
      }

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
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : subscriptions.isEmpty
              ? const Center(child: Text('暂无订阅'))
              : RefreshIndicator(
                onRefresh: _refreshSubscriptions,
                child: ListView.builder(
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

                    return Card(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          setState(() => selectedId = sub.id);
                          final settings = await readYamlAsObject(settingsPath);
                          settings['selected'] = sub.id;
                          await writeYamlFromObject(settings, settingsPath);
                          await _onSubscriptionTap(sub.id);
                        },
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 上传下载进度条和信息
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            height: 12,
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            child: Row(
                                              children: [
                                                if (sub.upload > 0)
                                                  Expanded(
                                                    flex: scale(sub.upload),
                                                    child: Container(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    ),
                                                  ),
                                                if (sub.download > 0)
                                                  Expanded(
                                                    flex: scale(sub.download),
                                                    child: Container(
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                    ),
                                                  ),
                                                Expanded(
                                                  flex: (100 -
                                                          scale(sub.upload) -
                                                          scale(sub.download))
                                                      .clamp(0, 100),
                                                  child: Container(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.surface,
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
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sub.expire == 0
                                              ? '到期时间: ∞'
                                              : '到期时间: ${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).year}-'
                                                  '${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).month}-'
                                                  '${DateTime.fromMillisecondsSinceEpoch(sub.expire * 1000).day}',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '上次更新: ${formatTimeAgo(sub.update)}',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      PopupMenuButton<int>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 20,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                        onSelected: (value) async {
                                          final settings =
                                              await readYamlAsObject(
                                                settingsPath,
                                              );
                                          final ua = settings['ua'];
                                          final timeout = settings['timeout'];
                                          switch (value) {
                                            case 1: // 刷新
                                              final close =
                                                  await showLoadingDialog(
                                                    context,
                                                    title: '刷新中...',
                                                  );
                                              try {
                                                final downloadResult =
                                                    await downloadYamlFile(
                                                      sub.link,
                                                      ua,
                                                      sub.id,
                                                      timeout,
                                                    );
                                                final updatedSub =
                                                    SubscriptionInfo(
                                                      id: downloadResult.id,
                                                      link: downloadResult.link,
                                                      label:
                                                          downloadResult.label,
                                                      upload:
                                                          downloadResult.upload,
                                                      download:
                                                          downloadResult
                                                              .download,
                                                      total:
                                                          downloadResult.total,
                                                      expire:
                                                          downloadResult.expire,
                                                      update:
                                                          downloadResult.update,
                                                    );
                                                final index = subscriptions
                                                    .indexWhere(
                                                      (s) => s.id == sub.id,
                                                    );
                                                if (index != -1)
                                                  subscriptions[index] =
                                                      updatedSub;
                                                final data = {
                                                  'subscriptions':
                                                      subscriptions
                                                          .map((s) => s.toMap())
                                                          .toList(),
                                                };
                                                await writeYamlFromObject(
                                                  data,
                                                  subscriptionsPath,
                                                );
                                                setState(() {});
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('刷新失败: $e'),
                                                  ),
                                                );
                                              } finally {
                                                if (mounted) close();
                                              }
                                              break;
                                            case 2: // 删除
                                              _deleteSubscription(context, sub);
                                              break;
                                            case 3: // 复制链接
                                              await Clipboard.setData(
                                                ClipboardData(text: sub.link),
                                              );
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('链接已复制'),
                                                ),
                                              );
                                              break;
                                          }
                                        },
                                        itemBuilder:
                                            (_) => [
                                              PopupMenuItem(
                                                value: 1,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.refresh,
                                                      size: 18,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('刷新'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 2,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('删除'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 3,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.copy,
                                                      size: 18,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('复制链接'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubscription,
        child: const Icon(Icons.add),
      ),
    );
  }
}
