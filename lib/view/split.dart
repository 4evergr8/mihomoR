import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:mihomoR/widget.dart';

class SplitView extends StatefulWidget {
  const SplitView({super.key});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Application> apps = [];
  List<Application> filteredApps = [];
  bool isLoading = true;
  String searchQuery = '';
  bool switchValue = false;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final appList = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
      );
      appList.sort((a, b) => a.appName.compareTo(b.appName));
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
    filteredApps = apps.where((app) =>
      app.appName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      app.packageName.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
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
                  child: Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 16),
                      Switch(
                        value: switchValue,
                        onChanged: (value) {
                          setState(() => switchValue = value);
                        },
                      ),
                    ],
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: app is ApplicationWithIcon
                                    ? Image.memory(
                                        app.icon,
                                        width: 40,
                                        height: 40,
                                      )
                                    : const Icon(Icons.android, size: 40),
                                title: Text(app.appName),
                                subtitle: Text(app.packageName),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton(
              heroTag: 'button1',
              onPressed: () {
                // TODO: button 1 action
              },
              child: const Icon(Icons.add),
            ),
          ),
          FloatingActionButton(
            heroTag: 'button2',
            onPressed: () {
              // TODO: button 2 action
            },
            child: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
