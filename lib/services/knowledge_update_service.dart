import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class KnowledgeUpdateService {
  static const String jsonFileName = 'coach_rules.json';
  static const String remoteJsonUrl =
      'https://github.com/MrKedow/Fitness-Tracker/blob/Android-Dev/assets/coach_rules.json';

  static Future<Map<String, int>> getStats() async {
    final file = await _getJsonFile();
    final data = await _loadJson(file);
    return {
      '科学事实': (data['scientific_facts'] as List?)?.length ?? 0,
      '最新研究': (data['research_summaries'] as List?)?.length ?? 0,
      '打破迷思': (data['myth_busters'] as List?)?.length ?? 0,
      '训练方案': (data['training_protocols'] as List?)?.length ?? 0,
      '小贴士': (data['tips'] as List?)?.length ?? 0,
      '鼓励语': (data['encouragements'] as List?)?.length ?? 0,
    };
  }

  /// 从 GitHub 下载最新 JSON 并与本地合并
  static Future<bool> runUpdate() async {
    print('📡 开始从 GitHub 更新知识库...');
    try {
      final response = await http.get(Uri.parse(remoteJsonUrl));
      if (response.statusCode != 200) {
        print('❌ 下载失败，状态码: ${response.statusCode}');
        return false;
      }

      final remoteData = json.decode(response.body) as Map<String, dynamic>;
      final jsonFile = await _getJsonFile();
      Map<String, dynamic> localData = await _loadJson(jsonFile);

      // 合并（只添加新条目，不删除）
      for (final category in [
        'scientific_facts',
        'research_summaries',
        'myth_busters',
        'training_protocols',
        'tips',
        'encouragements'
      ]) {
        final localSet = Set<String>.from(localData[category] as List? ?? []);
        final remoteList = remoteData[category] as List? ?? [];
        for (final item in remoteList) {
          if (item is String && item.isNotEmpty && !localSet.contains(item)) {
            localData[category] = [...localSet, ...remoteList].toList();
            // 重新构建 localSet 避免重复添加
            break;
          }
        }
      }

      await _saveJson(jsonFile, localData);
      print('🎉 知识库更新完成！');
      return true;
    } catch (e) {
      print('❌ 更新失败: $e');
      return false;
    }
  }

  // ========== 文件操作（保持不变） ==========
  static Future<File> _getJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$jsonFileName');
    if (!await file.exists()) {
      final defaultContent = await rootBundle.loadString('assets/$jsonFileName');
      await file.writeAsString(defaultContent);
    }
    return file;
  }

  static Future<Map<String, dynamic>> _loadJson(File file) async {
    final content = await file.readAsString();
    return json.decode(content);
  }

  static Future<void> _saveJson(File file, Map<String, dynamic> data) async {
    await file.writeAsString(json.encode(data), flush: true);
  }
}