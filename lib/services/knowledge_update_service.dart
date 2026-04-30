import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class KnowledgeUpdateService {
  static const String jsonFileName = 'coach_rules.json';
  static const List<String> _mirrorUrls = [
    'https://raw.githubusercontent.com/MrKedow/Fitness-Tracker/Android-Dev/assets/coach_rules.json',
    'https://cdn.jsdelivr.net/gh/MrKedow/Fitness-Tracker@Android-Dev/assets/coach_rules.json',
    'https://raw.sevencdn.com/MrKedow/Fitness-Tracker/Android-Dev/assets/coach_rules.json',
  ];

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// 获取当前本地 JSON 文件中各分类的条目数量（直接从文件读取）
  static Future<Map<String, int>> getStats() async {
    final file = await _getJsonFile();
    print('📊 getStats 读取文件: ${file.path}');
    final data = await _loadJson(file);
    final stats = {
      '科学事实': (data['scientific_facts'] as List?)?.length ?? 0,
      '最新研究': (data['research_summaries'] as List?)?.length ?? 0,
      '打破迷思': (data['myth_busters'] as List?)?.length ?? 0,
      '训练方案': (data['training_protocols'] as List?)?.length ?? 0,
      '小贴士': (data['tips'] as List?)?.length ?? 0,
      '鼓励语': (data['encouragements'] as List?)?.length ?? 0,
    };
    print('📊 统计结果: $stats');
    return stats;
  }

  /// 从 GitHub 下载最新 JSON 并直接替换本地文件，返回是否成功以及新的统计信息
  static Future<({bool success, Map<String, int>? stats})>
      runUpdateWithStats() async {
    print('📡 开始从 GitHub 更新知识库...');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 遍历所有镜像，成功则返回
    for (final baseUrl in _mirrorUrls) {
      final remoteUrl = '$baseUrl?t=$timestamp';
      print('🌐 尝试镜像: $remoteUrl');

      // 对每个镜像进行重试（最多3次）
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('  尝试第 $attempt 次下载...');
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(remoteUrl));
          request.headers.addAll(_headers);
          final response = await client.send(request).timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  client.close();
                  throw TimeoutException('连接超时');
                },
              );
          final responseBody = await http.Response.fromStream(response);
          client.close();

          if (responseBody.statusCode == 200) {
            final body = responseBody.body;
            print('✅ 下载成功，内容长度: ${body.length} 字符');
            final preview = body.length > 200 ? body.substring(0, 200) : body;
            print('📄 内容预览: $preview...');

            // 直接覆盖本地文件
            final jsonFile = await _getJsonFile();
            await jsonFile.writeAsString(body, flush: true);
            print('💾 已写入文件: ${jsonFile.path}');
            print('📏 写入后文件大小: ${await jsonFile.length()} 字节');

            // 立即重新读取并解析，验证写入内容
            final newData = await _loadJson(jsonFile);
            final scientificCount =
                (newData['scientific_facts'] as List?)?.length ?? 0;
            print('🔍 写入后 scientific_facts 实际数量: $scientificCount');

            if (scientificCount < 100) {
              print(
                  '⚠️ 警告：下载的内容中 scientific_facts 只有 $scientificCount 条，可能不是最新版本！');
            }

            final newStats = {
              '科学事实': scientificCount,
              '最新研究': (newData['research_summaries'] as List?)?.length ?? 0,
              '打破迷思': (newData['myth_busters'] as List?)?.length ?? 0,
              '训练方案': (newData['training_protocols'] as List?)?.length ?? 0,
              '小贴士': (newData['tips'] as List?)?.length ?? 0,
              '鼓励语': (newData['encouragements'] as List?)?.length ?? 0,
            };
            print('🎉 知识库更新完成！新统计: $newStats');
            return (success: true, stats: newStats);
          } else {
            print('❌ HTTP 错误: ${responseBody.statusCode}');
            if (attempt == 3) break; // 当前镜像3次失败，尝试下一个镜像
            await Future.delayed(Duration(seconds: attempt));
          }
        } catch (e) {
          print('❌ 尝试 $attempt 失败: $e');
          if (attempt == 3) break; // 当前镜像3次失败，尝试下一个镜像
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // 所有镜像均失败
    print('❌ 所有镜像均失败，更新未完成');
    return (success: false, stats: null);
  }

  /// 保持原有的 runUpdate 方法兼容性
  static Future<bool> runUpdate() async {
    final result = await runUpdateWithStats();
    return result.success;
  }

  static Future<File> _getJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$jsonFileName');
    if (!await file.exists()) {
      print('📁 本地文件不存在，从 assets 复制初始文件');
      final defaultContent =
          await rootBundle.loadString('assets/$jsonFileName');
      await file.writeAsString(defaultContent);
    }
    print('📁 本地文件路径: ${file.path}');
    return file;
  }

  static Future<Map<String, dynamic>> _loadJson(File file) async {
    final content = await file.readAsString();
    return json.decode(content);
  }
}