import 'dart:io';
import 'package:yaml_codec/yaml_codec.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// 下载 YAML 文件并保存到 /data/adb/mihomo
Future<Map<String, dynamic>> downloadYamlFile(String url, String ua, String id, int timeout) async {
  final dio = Dio();
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$id.yaml';

  try {
    final response = await dio.download(url, filePath, options: Options(responseType: ResponseType.bytes, followRedirects: true, headers: {'User-Agent': ua}, connectTimeout: Duration(seconds: timeout), sendTimeout: Duration(seconds: timeout), receiveTimeout: Duration(seconds: timeout)));

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

    // 校验 YAML
    try {
      const yamlCodec = YamlCodec();
      yamlCodec.decode(text);
    } catch (e) {
      throw Exception('YAML 解析失败: $e');
    }

    final result = await Process.run('su', ['-c', 'mkdir -p /data/adb/mihomo && cp $filePath /data/adb/mihomo/$id.yaml && chmod 777 /data/adb/mihomo/$id.yaml']);

    if (result.exitCode != 0) {
      throw Exception('root 拷贝失败: ${result.stderr}');
    }

    return {'id': id, 'link': url, 'label': label, 'upload': upload, 'download': downloadBytes, 'total': total, 'expire': expire, 'update': DateTime.now().millisecondsSinceEpoch.toString()};
  } catch (e) {
    final f = File(filePath);
    if (await f.exists()) {
      await f.delete();
    }
    rethrow;
  }
}
