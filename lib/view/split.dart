import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:mihomoR/widget.dart';

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
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final appList = await FlutterDeviceApps.listApps(
        includeSystem: true,
        includeIcons: true,
      );

      appList.sort((a, b) =>
          (a.appName ?? '').toLowerCase().compareTo((b.appName ?? '').toLowerCase()));

      setState(() {
        apps = appList;
        _filterApps();
        isLoading = false;
      });
    } catch (e) {
      showErrorSnackBarGlobal('$e');
      setState(() => isLoading = false);
    }
  }

  void _filterApps() {
    final query = searchQuery.toLowerCase();
    filteredApps = apps
        .where((app) =>
    app.appName != null &&
        app.packageName != null &&
        (app.appName!.toLowerCase().contains(query) ||
            app.packageName!.toLowerCase().contains(query)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('分应用')),
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
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterApps();
                });
              },
            ),
          ),
          Expanded(
            child: filteredApps.isEmpty
                ? const Center(child: Text('无应用'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                Uint8List? iconBytes = app.iconBytes;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: iconBytes != null
                        ? Image.memory(iconBytes, width: 40, height: 40)
                        : const Icon(Icons.android, size: 40),
                    title: Text(app.appName ?? ''),
                    subtitle: Text(app.packageName ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: handle tap
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'button1',
        onPressed: () {
          // TODO: button action
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}