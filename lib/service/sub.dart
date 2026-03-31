import 'dart:io';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// 下载结果
class DownloadResult {
  final String id;
  final String link;
  final String label;
  final int upload;
  final int download;
  final int total;
  final int expire;
  final String update;

  DownloadResult({
    required this.id,
    required this.link,
    required this.label,
    required this.upload,
    required this.download,
    required this.total,
    required this.expire,
    required this.update,
  });
}

/// 下载 YAML 文件并保存到 /data/adb/mihomo
Future<DownloadResult> downloadYamlFile(
  String url,
  String ua,
  String id,
  int timeout,
) async {
  final dio = Dio();
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$id.yaml';
  try {
    final response = await dio.download(
      url,
      filePath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {'User-Agent': ua},
        connectTimeout: Duration(seconds: timeout),
        sendTimeout: Duration(seconds: timeout),
        receiveTimeout: Duration(seconds: timeout),
      ),
    );

    final headers = response.headers.map;
    String label = id;

    final cd = headers['content-disposition']?.first;
    if (cd != null) {
      final fileNameStar = RegExp(
        r"filename\*\s*=\s*([^;]+)",
      ).firstMatch(cd)?.group(1);
      if (fileNameStar != null) {
        final parts = fileNameStar.split("''");
        if (parts.length == 2) {
          try {
            label = Uri.decodeComponent(parts[1]);
          } catch (_) {}
        }
      }

      final fileName = RegExp(r'filename="?([^"]+)"?').firstMatch(cd)?.group(1);
      if (fileName != null && fileName.isNotEmpty) label = fileName;
    }

    int upload = 0, downloadBytes = 0, total = 0, expire = 0;

    final userInfoRaw = headers['subscription-userinfo']?.first;
    if (userInfoRaw != null && userInfoRaw.isNotEmpty) {
      final parts = userInfoRaw.split(';');

      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length != 2) continue;

        final key = kv[0].trim();
        final value = int.tryParse(kv[1].trim()) ?? 0;

        switch (key) {
          case 'upload':
            upload = value;
            break;
          case 'download':
            downloadBytes = value;
            break;
          case 'total':
            total = value;
            break;
          case 'expire':
            expire = value;
            break;
        }
      }
    }

    final file = File(filePath);
    final text = await file.readAsString();

    try {
      const yamlCodec = YamlCodec();
      yamlCodec.decode(text);
    } catch (e) {
      throw Exception('YAML 解析失败: $e');
    }

    final result = await Process.run('su', [
      '-c',
      'mkdir -p /data/adb/mihomo && cp $filePath /data/adb/mihomo/$id.yaml && chmod 777 /data/adb/mihomo/$id.yaml',
    ]);

    if (result.exitCode != 0) {
      throw Exception('root 拷贝失败: ${result.stderr}');
    }

    return DownloadResult(
      id: id,
      link: url,
      label: label,
      upload: upload,
      download: downloadBytes,
      total: total,
      expire: expire,
      update: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  } catch (e) {
    final f = File(filePath);
    if (await f.exists()) {
      await f.delete();
    }
    rethrow;
  }
}

/// 合并 YAML 对象
Map<String, dynamic> overwriteYamlObject(
  Map<String, dynamic> base,
  Map<String, dynamic> patch,
) {
  final result = Map<String, dynamic>.from(base);

  for (final key in patch.keys) {
    result[key] = patch[key];
  }

  return result;
}

/// 订阅数据类
class SubscriptionInfo {
  String id;
  String link;
  String label;
  int upload;
  int download;
  int total;
  int expire;
  String update;

  SubscriptionInfo({
    required this.id,
    required this.link,
    required this.label,
    required this.upload,
    required this.download,
    required this.total,
    required this.expire,
    required this.update,
  });

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      id: map['id'].toString(),
      link:
          map['link'] as String? ??
          'https://raw.githubusercontent.com/4evergr8/MihomoRoot/refs/heads/main/mihomo/example.yaml',
      label: map['label'] as String? ?? '订阅',
      upload: map['upload'] as int? ?? 0,
      download: map['download'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      expire: map['expire'] as int? ?? 0,
      update: map['update'] as String? ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'link': link,
      'label': label,
      'upload': upload,
      'download': download,
      'total': total,
      'expire': expire,
      'update': update,
    };
  }
}
