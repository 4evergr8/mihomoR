import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/yaml.dart';

class ControlView extends StatefulWidget {
  const ControlView({super.key});

  @override
  State<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends State<ControlView> {
  final String settingsPath = '/data/adb/mihomo/settings.yaml';

  String startCmd = '';
  String stopCmd = '';
  String webuiUrl = '';
  String checkCmd = '';
  String checkResult = '--';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await readYamlAsObject(settingsPath);
    setState(() {
      startCmd = settings['start'] ?? '';
      stopCmd = settings['kill'] ?? '';
      webuiUrl = 'http://127.0.0.1:${settings['port'] ?? 9090}/ui';
      checkCmd = settings['check'] ?? '';
    });
    _runCheck();
  }

  Future<void> start() async {
    if (startCmd.isEmpty) return;
    await Process.start("sh", ["-c", startCmd]);
  }

  Future<void> stop() async {
    if (stopCmd.isEmpty) return;
    await Process.start("sh", ["-c", stopCmd]);
  }

  Future<void> openWeb() async {
    if (webuiUrl.isEmpty) return;
    final uri = Uri.parse(webuiUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _runCheck() async {
    if (checkCmd.isEmpty) return;
    try {
      final result = await Process.run("sh", ["-c", checkCmd]);
      if (!mounted) return;
      setState(() {
        checkResult = result.stdout.toString().trim();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        checkResult = '错误: $e';
      });
    }
  }

  Widget _buildButtonRow({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required String value,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              minimumSize: const Size(120, 50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          TextField(
            controller: TextEditingController(text: checkResult),
            readOnly: true,
            maxLines: null,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(8),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _runCheck,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildButtonRow(
              label: '启动',
              icon: Icons.play_arrow,
              onPressed: start,
              value: startCmd,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            _buildButtonRow(
              label: '停止',
              icon: Icons.stop,
              onPressed: stop,
              value: stopCmd,
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            _buildButtonRow(
              label: 'WEBUI',
              icon: Icons.language,
              onPressed: openWeb,
              value: webuiUrl,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            _buildCheckBox(),
          ],
        ),
      ),
    );
  }
}