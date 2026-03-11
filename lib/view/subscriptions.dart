import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../service/sub.dart';
import '../service/yaml.dart';
import '../widget.dart';
import 'package:fluttertoast/fluttertoast.dart';


class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  List<SubscriptionInfo> subscriptions = [];
  bool isLoading = true;
  final String subscriptionsPath = '/data/adb/mihomo/subscriptions.yaml';
  final String settingsPath = '/data/adb/mihomo/settings.yaml';
  final String rewritePath = '/data/adb/mihomo/rewrite.yaml';
  final String configPath = '/data/adb/mihomo/config.yaml';

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  /// 点击订阅
  Future<void> _onSubscriptionTap(String id) async {
    final base = await readYamlAsObject("data/adb/mihomo/$id.yaml");
    final patch = await readYamlAsObject(rewritePath);
    final data= overwriteYamlObject(base,patch);
    await writeYamlFromObject(data,configPath);
    final settings = await readYamlAsObject(settingsPath);
    final dio = Dio();
    final port = settings['port'];
    await dio.put('http://127.0.0.1:$port/configs?force=true');

  }

  /// 刷新订阅
  Future<void> _refreshSubscriptions() async {
    setState(() => isLoading = true);
    if (!mounted) return;
    final close = await showLoadingDialog(context, title: '加载中...');

    try {
      // 读取本地 YAML
      final data = await readYamlAsObject(subscriptionsPath);
      final list =
      (data['subscriptions'] is List) ? (data['subscriptions'] as List) : [];

      // 遍历每个订阅，刷新
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
              uploaded: downloadResult.upload,
              downloaded: downloadResult.download,
              total: downloadResult.total,
              expire: downloadResult.expire,
            ),
          );
          close();
        } catch (_) {
          close();
          updatedSubs.add(sub);
        }
      }

      // 写回 YAML
      final newData = {
        'subscriptions': updatedSubs.map((s) => s.toMap()).toList(),
      };
      await writeYamlFromObject(newData, subscriptionsPath);

      // 更新界面
      setState(() => subscriptions = updatedSubs);
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
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
    } catch (e) {
      subscriptions = [];
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      final downloadResult = await downloadYamlFile(result, ua,id);
      Fluttertoast.showToast(
        msg: "下载完成",
        toastLength: Toast.LENGTH_SHORT, // 显示时长，SHORT 或 LONG
        gravity: ToastGravity.BOTTOM,     // 显示在屏幕底部
        backgroundColor: Colors.black87,  // 背景色
        textColor: Colors.white,          // 文字颜色
        fontSize: 14.0,                   // 文字大小
      );
      subscriptions.add(
        SubscriptionInfo(
          id: downloadResult.id,
          link: downloadResult.link,
          label: downloadResult.label,
          uploaded: downloadResult.upload,
          downloaded: downloadResult.download,
          total: downloadResult.total,
          expire: downloadResult.expire,
        ),
      );

      final data = {
        'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
      };

      await writeYamlFromObject(data, subscriptionsPath);
      Fluttertoast.showToast(
        msg: "更新完成",
        toastLength: Toast.LENGTH_SHORT, // 显示时长，SHORT 或 LONG
        gravity: ToastGravity.BOTTOM,     // 显示在屏幕底部
        backgroundColor: Colors.black87,  // 背景色
        textColor: Colors.white,          // 文字颜色
        fontSize: 14.0,                   // 文字大小
      );

      setState(() {});
      close();
    } catch (e) {
      close();
      if (!mounted) return;
      await showErrorDialog(context, '加载错误', e);

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

          return InkWell(
            onTap: () => _onSubscriptionTap(sub.id),
            borderRadius: BorderRadius.circular(12),
            child: Card(
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
                      '订阅 ${sub.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: sub.downloaded,
                            child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary,
                            ),
                          ),
                          Expanded(
                            flex: sub.total -
                                sub.uploaded -
                                sub.downloaded,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      sub.total == 0
                          ? '上传: ∞  下载: ∞  剩余: ∞'
                          : '上传: ${sub.uploaded}GB  下载: ${sub.downloaded}GB  剩余: ${sub.total - sub.uploaded - sub.downloaded}GB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 8),

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