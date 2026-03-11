import 'dart:io';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// 下载结果
class DownloadResult {
  final String id;
  final String label;
  final int upload;
  final int download;
  final int total;
  final int expire;

  DownloadResult({
    required this.id,
    required this.label,
    required this.upload,
    required this.download,
    required this.total,
    required this.expire,
  });
}

/// 下载 YAML 文件并保存到 /data/adb/mihomo
Future<DownloadResult> downloadYamlFile(String url, String ua) async {
  final dio = Dio();
  final dir = await getApplicationDocumentsDirectory();
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  final filePath = '${dir.path}/$id.yaml';

  try {
    final response = await dio.download(
      url,
      filePath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {
          'User-Agent': ua,
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    final headers = response.headers.map;

    String label = id;
    final cd = headers['content-disposition']?.first;
    if (cd != null) {
      final fileNameStar = RegExp(r"filename\*\s*=\s*([^;]+)").firstMatch(cd)?.group(1);
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

    final result = await Process.run(
      'su',
      ['-c', 'mkdir -p /data/adb/mihomo && cp $filePath /data/adb/mihomo/$id.yaml && chmod 600 /data/adb/mihomo/$id.yaml'],
    );
    if (result.exitCode != 0) throw Exception('root 拷贝失败: ${result.stderr}');

    return DownloadResult(
      id: id,
      label: label,
      upload: upload,
      download: downloadBytes,
      total: total,
      expire: expire,
    );
  } catch (e) {
    final f = File(filePath);
    if (await f.exists()) await f.delete();
    rethrow;
  }
}

/// 合并 YAML 对象
Map<String, dynamic> overwriteYamlObject(Map<String, dynamic> base, Map<String, dynamic> patch) {
  final result = <String, dynamic>{};

  for (final key in base.keys) {
    if (patch.containsKey(key)) {
      final baseValue = base[key];
      final patchValue = patch[key];
      if (baseValue is Map && patchValue is Map) {
        result[key] = overwriteYamlObject(
          Map<String, dynamic>.from(baseValue),
          Map<String, dynamic>.from(patchValue),
        );
      } else {
        result[key] = patchValue;
      }
    } else {
      result[key] = base[key];
    }
  }

  for (final key in patch.keys) {
    if (!base.containsKey(key)) {
      result[key] = patch[key];
    }
  }

  return result;
}

/// 订阅数据类
class SubscriptionInfo {
  String id;
  String label;
  int uploaded;
  int downloaded;
  int total;
  DateTime expireDate;

  SubscriptionInfo({
    required this.id,
    required this.label,
    required this.uploaded,
    required this.downloaded,
    required this.total,
    required this.expireDate,
  });

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      id: map['id'].toString(),
      label: map['label'] as String? ?? '订阅',
      uploaded: map['up'] as int? ?? 0,
      downloaded: map['down'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      expireDate: DateTime.fromMillisecondsSinceEpoch(
        (map['expire'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'up': uploaded,
      'down': downloaded,
      'total': total,
      'expire': expireDate.millisecondsSinceEpoch ~/ 1000,
    };
  }
}