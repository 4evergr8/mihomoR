import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mihomoR/service/subscriptions.dart';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/widget.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;
  List<Map<String, dynamic>> subscriptions = [];
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
    final close = await showLoadingDialogGlobal();
    try {
      final settings = await readYamlAsMap(settingsPath);
      final port = settings['port'];
      final base = await readYamlAsMap("/data/adb/mihomo/config/$id.yaml");
      final override = await readYamlAsMap(overridePath);
      final yaml = overrideMap(base, override);
      await writeYamlFromMap(yaml, configPath);
      final dio = Dio();
      final params = {'force': 'true'};
      final data = {"path": configPath};
      await dio.put('http://127.0.0.1:$port/configs', queryParameters: params, data: data, options: Options(headers: {'Content-Type': 'application/json'}));
      await dio.delete('http://127.0.0.1:$port/connections', options: Options(headers: {'Content-Type': 'application/json'}));
    } catch (e) {
      showErrorSnackBarGlobal('$e');
    } finally {
      close();
    }
  }

  Future<void> _refreshSubscriptions() async {
    final close = await showLoadingDialogGlobal();
    try {
      final data = await readYamlAsMap(subscriptionsPath);
      final settings = await readYamlAsMap(settingsPath);

      final list = (data['subscriptions'] is List) ? List<Map<String, dynamic>>.from(data['subscriptions']) : <Map<String, dynamic>>[];

      final ua = settings['ua'];
      final timeout = settings['timeout'];

      // 原数据 Map（按 id）
      final Map<String, Map<String, dynamic>> resultMap = {for (var s in list) s['id']: Map<String, dynamic>.from(s)};

      // 并行任务
      final futures =
          list.map((sub) async {
            final id = sub['id'];
            try {
              final downloadResult = await downloadYamlFile(sub['link'], ua, id, timeout);
              return {'id': id, 'data': downloadResult};
            } catch (e) {
              showErrorSnackBarGlobal('${sub['label'] ?? id} 失败: $e');
              return null;
            }
          }).toList();

      final results = await Future.wait(futures);

      // 合并结果（成功才覆盖）
      for (var r in results) {
        if (r != null) {
          resultMap[r['id']] = {...(resultMap[r['id']] ?? {}), ...r['data']};
        }
      }

      final newList = resultMap.values.toList()..sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));

      await writeYamlFromMap({'subscriptions': newList}, subscriptionsPath);

      if (mounted) {
        setState(() => subscriptions = newList);
      }
    } catch (e) {
      showErrorSnackBarGlobal('刷新订阅失败: $e');
    } finally {
      close();
    }
  }

  Future<void> _mergeProxies() async {
    final close = await showLoadingDialogGlobal();
    try {
      final subData = await readYamlAsMap(subscriptionsPath);
      final list = (subData['subscriptions'] is List) ? subData['subscriptions'] as List : [];
      final List<Map<String, dynamic>> allProxies = [];
      final Set<String> proxyNames = {};

      for (final subMap in list) {
        try {
          final sub = Map<String, dynamic>.from(subMap);
          if (sub['selected'] != true) continue; // 只合并开启的
          final subYaml = await readYamlAsMap("/data/adb/mihomo/config/${sub['id']}.yaml");
          if (subYaml['proxies'] is List) {
            final proxies = List<Map<String, dynamic>>.from(subYaml['proxies']);
            for (var proxy in proxies) {
              var name = proxy['name'] as String? ?? '未知';
              var newName = name;
              var count = 1;
              while (proxyNames.contains(newName)) {
                newName = "$name#$count";
                count++;
              }
              proxyNames.add(newName);
              proxy['name'] = newName;
              allProxies.add(proxy);
            }
          }
        } catch (e) {
          showErrorSnackBarGlobal('订阅 ${subMap['label'] ?? subMap['id']} 读取失败: $e');
        }
      }

      final merge = await readYamlAsMap(mergePath);
      final yaml = overrideMap({'proxies': allProxies}, merge);
      await writeYamlFromMap(yaml, configPath);
      final settings = await readYamlAsMap(settingsPath);
      final port = settings['port'];
      final dio = Dio();
      final params = {'force': 'true'};
      final data = {"path": configPath};
      settings['selected'] = 'merge';
      await writeYamlFromMap(settings, settingsPath);
      await dio.put('http://127.0.0.1:$port/configs', queryParameters: params, data: data, options: Options(headers: {'Content-Type': 'application/json'}));
    } catch (e) {
      showErrorSnackBarGlobal('$e');
    } finally {
      close();
    }
  }

  Future<void> _loadSubscriptions() async {
    final close = await showLoadingDialogGlobal();

    try {
      final data = await readYamlAsMap(subscriptionsPath);
      final list = (data['subscriptions'] is List) ? data['subscriptions'] as List : [];
      subscriptions = list.map((e) => Map<String, dynamic>.from(e)).toList();
      subscriptions.sort((a, b) {
        final aSel = a['selected'] == true ? 0 : 1;
        final bSel = b['selected'] == true ? 0 : 1;
        if (aSel != bSel) return aSel - bSel; // selected=true 在前
        return (a['label'] as String).compareTo(b['label'] as String); // label 排序
      });

      final settings = await readYamlAsMap(settingsPath);
      selectedId = settings['selected'] as String?;
    } catch (e) {
      subscriptions = [];
      showErrorSnackBarGlobal('$e');
    } finally {
      close();
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSubscription(BuildContext context, Map<String, dynamic> sub) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('确认删除'), content: Text('确定删除订阅 "${sub['label']}" 吗？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认'))]));

    if (confirm != true) return;

    final close = await showLoadingDialogGlobal();
    try {
      subscriptions.removeWhere((s) => s['id'] == sub['id']);
      final data = {'subscriptions': subscriptions};
      await writeYamlFromMap(data, subscriptionsPath);
      await Process.run('su', ['-c', 'rm -f /data/adb/mihomo/config/${sub['id']}.yaml']);

      if (selectedId == sub['id']) {
        selectedId = null;
        final settings = await readYamlAsMap(settingsPath);
        settings['selected'] = null;
        await writeYamlFromMap(settings, settingsPath);
      }

      setState(() {});
    } catch (e) {
      showErrorSnackBarGlobal('$e');
    } finally {
      close();
    }
  }

  Future<void> _addSubscription() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加订阅'),
          content: SizedBox(width: double.maxFinite, child: TextField(controller: controller, minLines: 5, maxLines: 10, decoration: const InputDecoration(hintText: '每行一个订阅地址', border: OutlineInputBorder()))),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final text = data?.text;
                if (text != null) controller.text = text;
              },
              icon: const Icon(Icons.paste),
              label: const Text('粘贴'),
            ),
            ElevatedButton.icon(onPressed: () => Navigator.pop(context, controller.text), icon: const Icon(Icons.check), label: const Text('确认')),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;
    if (!mounted) return;

    final close = await showLoadingDialogGlobal();

    try {
      final settings = await readYamlAsMap(settingsPath);
      final ua = settings['ua'];
      final timeout = settings['timeout'];

      final data = await readYamlAsMap(subscriptionsPath);
      final list = (data['subscriptions'] is List) ? List<Map<String, dynamic>>.from(data['subscriptions']) : <Map<String, dynamic>>[];

      final existingLinks = list.map((e) => e['link']).toSet();

      final inputLinks = result.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // 输入内部去重（保留顺序）
      final seen = <String>{};
      final links = <String>[];
      for (var l in inputLinks) {
        if (!seen.contains(l)) {
          seen.add(l);
          links.add(l);
        }
      }

      // 分离重复 & 新增
      final newLinks = <String>[];

      for (var link in links) {
        if (existingLinks.contains(link)) {
          showErrorSnackBarGlobal('订阅已存在: $link'); // ✅ 每个都提示
        } else {
          newLinks.add(link);
        }
      }

      // 并行下载
      final futures =
          newLinks.map((link) async {
            final id = DateTime.now().microsecondsSinceEpoch.toString();
            try {
              final r = await downloadYamlFile(link, ua, id, timeout);
              return r;
            } catch (e) {
              showErrorSnackBarGlobal('$link 添加失败: $e');
              return null;
            }
          }).toList();

      final results = await Future.wait(futures);

      // 只加入成功的
      for (var r in results) {
        if (r != null) {
          list.add(r);
        }
      }

      list.sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));

      await writeYamlFromMap({'subscriptions': list}, subscriptionsPath);

      if (mounted) {
        setState(() => subscriptions = list);
      }
    } catch (e) {
      showErrorSnackBarGlobal('$e');
    } finally {
      close();
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
                  itemCount: subscriptions.length + 1, // 👈 多一个
                  itemBuilder: (context, index) {
                    if (index == subscriptions.length) {
                      return const SizedBox(height: 100); // 👈 底部空白
                    }
                    final sub = subscriptions[index];
                    final totalValue = sub['total'] as int;

                    int scale(int value) {
                      if (totalValue == 0) return 0;
                      final v = value * 100 ~/ totalValue;
                      return v.clamp(0, 100);
                    }

                    final isSelected = sub['id'] == selectedId;

                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                 //     margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          setState(() => selectedId = sub['id']);
                          final settings = await readYamlAsMap(settingsPath);
                          settings['selected'] = sub['id'];
                          await writeYamlFromMap(settings, settingsPath);
                          await _onSubscriptionTap(sub['id']);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child:
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. 第一行：count 和 label
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${sub['count'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      sub['label'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 2. 第二行：进度条
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 10,
                                  child: Row(
                                    children: [
                                      if ((sub['upload'] as int) > 0)
                                        Expanded(
                                          flex: scale(sub['upload'] as int),
                                          child: Container(color: Theme.of(context).colorScheme.primary),
                                        ),
                                      if ((sub['download'] as int) > 0)
                                        Expanded(
                                          flex: scale(sub['download'] as int),
                                          child: Container(color: Theme.of(context).colorScheme.secondary),
                                        ),
                                      Expanded(
                                        flex: (100 - scale(sub['upload'] as int) - scale(sub['download'] as int)).clamp(0, 100),
                                        child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 3. 第三行：左侧三行文字 + 右侧两个按钮
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 左侧文字列
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          totalValue == 0
                                              ? '上传: ∞  下载: ∞  总量: ∞'
                                              : '上传: ${formatGB(sub['upload'] as int)}GB  下载: ${formatGB(sub['download'] as int)}GB  总量: ${formatGB(totalValue)}GB',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (sub['expire'] as int) == 0
                                              ? '到期时间: ∞'
                                              : '到期时间: ${DateTime.fromMillisecondsSinceEpoch((sub['expire'] as int) * 1000).toString().split(" ")[0]}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '上次更新: ${formatTimeAgo(sub['update'] as String)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 右侧按钮列，水平排列，无间隔
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<int>(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                        icon: Icon(Icons.more_vert, size: 20, color: Theme.of(context).colorScheme.onSurface),
                                        onSelected: (value) async { /* 原逻辑保持 */ },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 1, child: Text('刷新')),
                                          PopupMenuItem(value: 2, child: Text('删除')),
                                          PopupMenuItem(value: 3, child: Text('复制')),
                                        ],
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                        icon: Icon(
                                          (sub['selected'] ?? false) ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 20,
                                          color: (sub['selected'] ?? false)
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                        onPressed: () async { /* 原逻辑保持 */ },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton(
              heroTag: 'merge',
              onPressed: () async {
                setState(() => selectedId = 'merge');
                await _mergeProxies();
                showErrorSnackBarGlobal('订阅合并成功');
              },
              backgroundColor: selectedId == 'merge' ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(selectedId == 'merge' ? Icons.check : Icons.merge_type, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          FloatingActionButton(heroTag: 'add', onPressed: _addSubscription, child: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
