import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:mihomoR/service/path.dart';
import 'package:mihomoR/service/subscriptions.dart';


class SplitView extends StatefulWidget {
  const SplitView({super.key});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  List<AppInfo> apps = [];
  List<AppInfo> filteredApps = [];
  String searchQuery = '';
  bool isLoading = true;

  // 存储勾选的包名，包括 YAML 里存在但未安装的包名
  Set<String> selectedPackages = {};
  Set<String> yamlPackages = {};

  @override
  void initState() {
    super.initState();
    _loadAppsAndYaml();
  }

  Future<void> _loadAppsAndYaml() async {
    final override = await readYamlAsMap(overridePath);
    final includePackages = List<String>.from(override['tun']['include-package'] ?? []);
    yamlPackages = includePackages.toSet();
    selectedPackages = includePackages.toSet();

    final appList = await FlutterDeviceApps.listApps(
      includeSystem: true,
      includeIcons: true,
        onlyLaunchable: false
    );
    final validApps = appList.where((a) => a.packageName != null && a.appName != null).toList();

    // 将 YAML 中存在但未安装的包名生成虚拟 AppInfo（不显示图标）
    for (final pkg in yamlPackages) {
      if (!validApps.any((a) => a.packageName == pkg)) {
        validApps.add(AppInfo(appName: null, packageName: pkg, iconBytes: null));
      }
    }

    // 勾选的置顶
    validApps.sort((a, b) {
      final aSelected = selectedPackages.contains(a.packageName);
      final bSelected = selectedPackages.contains(b.packageName);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return (a.appName ?? '').toLowerCase().compareTo((b.appName ?? '').toLowerCase());
    });

    setState(() {
      apps = validApps;
      filteredApps = List.from(validApps);
      isLoading = false;
    });
  }

  void _filterApps(String query) {
    final q = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredApps = apps.where((app) =>
      (app.appName ?? '').toLowerCase().contains(q) ||
          (app.packageName ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _saveSelection() async {
    final checkedPackages = apps.where((a) => selectedPackages.contains(a.packageName)).map((a) => a.packageName!).toSet();
    final newInclude = {...checkedPackages, ...yamlPackages.difference(apps.map((e) => e.packageName!).toSet())};
    final override = await readYamlAsMap(overridePath);
    override['tun']['include-package'] = newInclude.toList();
    await writeYamlFromMap(override,overridePath);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('分流')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索应用',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterApps,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                final isChecked = selectedPackages.contains(app.packageName);
                Uint8List? iconBytes = app.iconBytes;
                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedPackages.add(app.packageName!);
                      } else {
                        selectedPackages.remove(app.packageName);
                      }
                    });
                  },
                  title: Text(app.appName ?? app.packageName ?? ''),
                  secondary: iconBytes != null
                      ? Image.memory(iconBytes, width: 40, height: 40)
                      : const Icon(Icons.android, size: 40),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSelection,
        child: const Icon(Icons.save),
      ),
    );
  }
}