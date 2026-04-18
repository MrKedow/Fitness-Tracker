import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class CoachCharacter extends StatefulWidget {
  final List<WorkoutRecord> records;
  const CoachCharacter({super.key, required this.records});

  @override
  State<CoachCharacter> createState() => _CoachCharacterState();
}

class _CoachCharacterState extends State<CoachCharacter> with TickerProviderStateMixin {
  String _currentImagePath = 'assets/吉祥物奔奔猫.gif';
  List<String> _presetImages = [];

  bool _isAnalyzing = false;
  String _aiResponse = '';
  String _displayedResponse = '';
  AnimationController? _typingController;

  final ScrollController _scrollController = ScrollController();
  AnimationController? _bounceController;
  bool _isAtBottom = true;
  bool _showScrollIndicator = false;

  Map<String, dynamic> _coachRules = {};
  bool _rulesLoaded = false;
  List<Map<String, dynamic>> _exerciseHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPresetImages();
    _loadUserPreference();
    _loadCoachRules();
    _typingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _typingController?.addListener(_updateTyping);
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _scrollController.addListener(_onScroll);
  }

  void _updateTyping() {
    if (!mounted) return;
    final len = (_aiResponse.length * (_typingController!.value)).toInt().clamp(0, _aiResponse.length);
    setState(() {
      _displayedResponse = _sanitizeText(_aiResponse.substring(0, len));
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = currentScroll >= maxScroll - 10;
    
    final needsScroll = maxScroll > 0;
    
    if (isAtBottom != _isAtBottom || needsScroll != _showScrollIndicator) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollIndicator = needsScroll;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _sanitizeText(String text) {
    // 移除了未使用的 testSpan 变量
    return text;
  }

  @override
  void dispose() {
    _typingController?.dispose();
    _bounceController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCoachRules() async {
    try {
      final String data = await rootBundle.loadString('assets/coach_rules.json');
      setState(() {
        _coachRules = json.decode(data);
        _rulesLoaded = true;
      });
    } catch (e) {
      debugPrint('加载规则文件失败: $e');
      _coachRules = {};
      _rulesLoaded = false;
    }
  }

  Future<void> _loadPresetImages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCustom = prefs.getStringList('coach_custom_images') ?? [];
    final defaultPreset = [
      'assets/吉祥物奔奔猫.gif',
      'assets/阿比盖尔.gif',
      'assets/奔跑.gif',
      'assets/超级赛亚人.png',
      'assets/搓搓手.gif',
      'assets/加油丸子.gif',
      'assets/开心云朵.gif',
      'assets/拳皇.gif',
      'assets/诗人.gif',
      'assets/无奈社畜.gif',
      'assets/熊猫头.gif',
      'assets/一起跳舞.gif',
    ];
    _presetImages = [...defaultPreset, ...savedCustom];
    setState(() {});
  }

  Future<void> _saveCustomImages() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultCount = 12;
    if (_presetImages.length > defaultCount) {
      final custom = _presetImages.sublist(defaultCount);
      await prefs.setStringList('coach_custom_images', custom);
    }
  }

  Future<void> _loadUserPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _currentImagePath = prefs.getString('coach_image') ?? 'assets/吉祥物奔奔猫.gif';
    setState(() {});
  }

  Future<void> _saveUserPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coach_image', _currentImagePath);
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  String _randomSelect(List<String> list) {
    if (list.isEmpty) return '';
    final random = Random();
    return list[random.nextInt(list.length)];
  }

  double? _predictNextWeight(String exerciseName, String part) {
    final exerciseData = _exerciseHistory
        .where((e) => e['name'] == exerciseName && e['part'] == part)
        .toList();
    
    if (exerciseData.length < 3) return null;
    
    final recent = exerciseData.reversed.take(5).toList().reversed.toList();
    final n = recent.length;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = (recent[i]['weight'] as num).toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    return intercept + slope * n;
  }

  void _showChangeImageMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择陪练形象',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._presetImages.map((img) => ListTile(
                    leading: img.startsWith('assets/')
                        ? Image.asset(img, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                        : Image.file(File(img), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                    title: Text(img.split('/').last.replaceAll('.gif', '').replaceAll('.png', '')),
                    trailing: _currentImagePath == img ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      setState(() => _currentImagePath = img);
                      _saveUserPreference();
                      Navigator.pop(context);
                      _showToast('形象已更换');
                    },
                  )),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                title: const Text('添加自定义图片'),
                subtitle: const Text('从相册选择 GIF 或 PNG', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'coach_${DateTime.now().millisecondsSinceEpoch}.png';
                    final savedPath = '${appDir.path}/$fileName';
                    await File(pickedFile.path).copy(savedPath);
                    setState(() {
                      _currentImagePath = savedPath;
                      _presetImages.add(savedPath);
                    });
                    _saveUserPreference();
                    await _saveCustomImages();
                    Navigator.pop(context);
                    _showToast('自定义形象已添加');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & (overlay?.paintBounds.size ?? Size.zero),
      ),
      items: const [
        PopupMenuItem(value: 'changeImage', child: Text('🎨 更改陪练形象')),
        PopupMenuItem(value: 'analyze', child: Text('📊 分析训练数据')),
      ],
    ).then((value) {
      if (value == 'changeImage') {
        _showChangeImageMenu();
      } else if (value == 'analyze') {
        _analyzeLocally();
      }
    });
  }

  double? _getPreviousWeight(List<WorkoutRecord> records, String name, String part, DateTime currentDate) {
    for (var record in records) {
      if (record.date.isAfter(currentDate)) continue;
      for (var p in record.projects) {
        if (p.name == name && p.part == part) {
          return p.weight;
        }
      }
    }
    return null;
  }

  Future<void> _analyzeLocally() async {
    setState(() {
      _isAnalyzing = true;
      _aiResponse = '';
      _displayedResponse = '';
      _typingController?.stop();
      _typingController?.reset();
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final records = widget.records;
    if (records.isEmpty) {
      setState(() {
        _aiResponse = "🏋️ 还没有训练记录哦～ 快去主页记录你的第一次努力吧！每一次举铁都值得被记住。";
        _isAnalyzing = false;
        _typingController?.forward(from: 0.0);
      });
      return;
    }

    // 收集数据（代码较长，保持原样，仅修改 withOpacity 部分在 build 中）
    int totalSessions = records.length;
    
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    DateTime startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime endOfWeekDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    
    int thisWeekSessions = 0;
    double thisWeekVolume = 0;
    for (var record in records) {
      DateTime recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAtSameMomentAs(startOfWeekDate) || 
          recordDate.isAtSameMomentAs(endOfWeekDate) ||
          (recordDate.isAfter(startOfWeekDate) && recordDate.isBefore(endOfWeekDate))) {
        thisWeekSessions++;
        for (var p in record.projects) {
          thisWeekVolume += (p.calculateWork() as num).toDouble();
        }
      }
    }
    
    String weekRange = '${startOfWeek.month}.${startOfWeek.day}-${endOfWeek.month}.${endOfWeek.day}';

    Map<String, int> partCount = {};
    Map<String, int> partSets = {};      // 每个部位的总组数
    Map<String, double> partVolume = {};
    Map<String, Set<String>> partRecordIds = {}; // 记录每个部位已经计数的记录 id，用于去重
    double totalWork = 0;
    int totalSets = 0;
    List<Map<String, dynamic>> recentProjects = [];
    _exerciseHistory = [];

    for (var record in records) {
      final recordId = record.id;   // 每条记录有唯一 id
      for (var project in record.projects) {
        if (project.name.isEmpty) continue;
        
        totalWork += project.calculateWork();
        totalSets += project.sets;
        
        // 初始化部位的去重集合
        if (!partRecordIds.containsKey(project.part)) {
          partRecordIds[project.part] = {};
        }
        // 如果这条记录还没有为该部位计数过，则增加训练次数
        if (!partRecordIds[project.part]!.contains(recordId)) {
          partRecordIds[project.part]!.add(recordId);
          partCount[project.part] = (partCount[project.part] ?? 0) + 1;
        }
        // 累加组数和做功（无论是否去重，组数和做功都要累加）
        partSets[project.part] = (partSets[project.part] ?? 0) + project.sets;
        partVolume[project.part] = (partVolume[project.part] ?? 0) + project.calculateWork();

        // 下面继续原有的 recentProjects 和 _exerciseHistory 添加代码（保持不变）
        recentProjects.add({
          'date': record.date,
          'name': project.name,
          'weight': project.weight,
          'sets': project.sets,
          'reps': project.repsPerSet,
          'part': project.part,
        });
        
        _exerciseHistory.add({
          'date': record.date,
          'name': project.name,
          'weight': project.weight,
          'sets': project.sets,
          'reps': project.repsPerSet,
          'part': project.part,
        });
      }
    }
    
    recentProjects.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    _exerciseHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final latest = recentProjects.isNotEmpty ? recentProjects.first : null;

    StringBuffer analysis = StringBuffer();
    
    if (_rulesLoaded && _coachRules.containsKey('openings')) {
      final openings = (_coachRules['openings'] as List).cast<String>();
      analysis.writeln(_randomSelect(openings));
    } else {
      analysis.writeln("🔍 让我看看你的训练数据～");
    }
    analysis.writeln();

    if (latest != null) {
      analysis.writeln("📅 最近一次训练 (${DateFormat('yyyy-MM-dd').format(latest['date'] as DateTime)}) 分析：");
      
      final latestRecord = records.firstWhere((r) => r.date == latest['date'], orElse: () => records.first);
      double accurateLatestWork = latestRecord.projects.fold(0.0, (sum, p) => sum + p.calculateWork());
      final latestKJ = (accurateLatestWork / 1000).toInt();
      
      String volumeLevel;
      if (accurateLatestWork > 50000) volumeLevel = 'high';
      else if (accurateLatestWork > 20000) volumeLevel = 'moderate';
      else volumeLevel = 'low';
      
      if (_rulesLoaded && _coachRules.containsKey('volume_analysis') && _coachRules['volume_analysis'].containsKey(volumeLevel)) {
        final responses = (_coachRules['volume_analysis'][volumeLevel] as List).cast<String>();
        analysis.writeln(_randomSelect(responses).replaceAll(r'${work}', latestKJ.toString()));
      } else {
        analysis.writeln("📊 本次训练总做功 ${latestKJ} 千焦。");
      }
      
      final latestParts = latestRecord.projects.map((p) => p.part).toSet().toList();
      final missingParts = ['胸', '背', '腿', '肩', '腹'].where((p) => !latestParts.contains(p)).toList();
      if (_rulesLoaded && _coachRules.containsKey('part_balance')) {
        if (missingParts.isEmpty) {
          final responses = (_coachRules['part_balance']['complete'] as List).cast<String>();
          analysis.writeln(_randomSelect(responses).replaceAll(r'${parts}', latestParts.join('、')));
        } else {
          final responses = (_coachRules['part_balance']['missing'] as List).cast<String>();
          analysis.writeln(_randomSelect(responses).replaceAll(r'${parts}', missingParts.join('、')));
        }
      } else {
        if (missingParts.isEmpty) {
          analysis.writeln("✅ 今天训练部位覆盖了 ${latestParts.join('、')}，非常全面！");
        } else {
          analysis.writeln("⚠️ 今天没有训练 ${missingParts.join('、')}，下次记得补上。");
        }
      }
      
      analysis.writeln("📋 项目详情：");
      for (var project in latestRecord.projects) {
        final prev = _getPreviousWeight(records, project.name, project.part, latestRecord.date);
        String line = "  • ${project.name} (${project.part})：${project.sets}组×${project.repsPerSet}次 @${project.weight}kg，做功${project.calculateWork().toInt()}J。";
        
        if (prev != null) {
          final diff = (project.weight - prev);
          String progressType;
          if (diff > 0) progressType = 'improved';
          else if (diff < 0) progressType = 'declined';
          else progressType = 'same';
          
          if (_rulesLoaded && _coachRules.containsKey('progress_tracking') && _coachRules['progress_tracking'].containsKey(progressType)) {
            final responses = (_coachRules['progress_tracking'][progressType] as List).cast<String>();
            final msg = _randomSelect(responses)
                .replaceAll(r'${name}', project.name)
                .replaceAll(r'${diff}', diff.abs().toStringAsFixed(1));
            line += ' ' + msg;
          } else {
            if (diff > 0) line += " 📈 比上次提升 ${diff.toStringAsFixed(1)}kg！";
            else if (diff < 0) line += " 📉 比上次下降 ${(-diff).toStringAsFixed(1)}kg。";
            else line += " 🔄 重量与上次持平。";
          }
        } else {
          if (_rulesLoaded && _coachRules.containsKey('progress_tracking') && _coachRules['progress_tracking'].containsKey('first')) {
            final responses = (_coachRules['progress_tracking']['first'] as List).cast<String>();
            final msg = _randomSelect(responses).replaceAll(r'${name}', project.name);
            line += ' ' + msg;
          } else {
            line += " ✨ 首次记录 ${project.name}，打好基础。";
          }
        }
        analysis.writeln(line);
        
        final predicted = _predictNextWeight(project.name, project.part);
        if (predicted != null && predicted > project.weight && _rulesLoaded && _coachRules.containsKey('predictions')) {
          final templates = (_coachRules['predictions']['templates'] as List).cast<String>();
          final weeks = ((predicted - project.weight) / 1.2).ceil().clamp(2, 12);
          final target = (project.weight + (predicted - project.weight) / 2).toStringAsFixed(1);
          final msg = _randomSelect(templates)
              .replaceAll(r'${name}', project.name)
              .replaceAll(r'${weeks}', weeks.toString())
              .replaceAll(r'${target}', target);
          analysis.writeln("    $msg");
        }
      }
      analysis.writeln();
    }

    analysis.writeln("📆 本周训练总结 ($weekRange)：");
    
    String freqLevel;
    if (thisWeekSessions >= 5) freqLevel = 'excellent';
    else if (thisWeekSessions >= 3) freqLevel = 'good';
    else if (thisWeekSessions >= 1) freqLevel = 'fair';
    else freqLevel = 'poor';
    
    if (_rulesLoaded && _coachRules.containsKey('week_frequency') && _coachRules['week_frequency'].containsKey(freqLevel)) {
      final responses = (_coachRules['week_frequency'][freqLevel] as List).cast<String>();
      analysis.writeln(_randomSelect(responses).replaceAll(r'${sessions}', thisWeekSessions.toString()));
    } else {
      if (thisWeekSessions >= 3) analysis.writeln("👍 本周训练了 $thisWeekSessions 次，频率不错。");
      else if (thisWeekSessions >= 1) analysis.writeln("📌 本周训练了 $thisWeekSessions 次，可以增加频率。");
      else analysis.writeln("⏰ 本周暂无训练，快动起来！");
    }
    
    final weekWorkKJ = (thisWeekVolume / 1000).toInt();
    if (thisWeekSessions > 0) {
      String weekVolumeLevel;
      if (thisWeekVolume > 150000) weekVolumeLevel = 'high';
      else if (thisWeekVolume > 60000) weekVolumeLevel = 'moderate';
      else weekVolumeLevel = 'low';
      
      if (_rulesLoaded && _coachRules.containsKey('week_volume') && _coachRules['week_volume'].containsKey(weekVolumeLevel)) {
        final responses = (_coachRules['week_volume'][weekVolumeLevel] as List).cast<String>();
        analysis.writeln(_randomSelect(responses).replaceAll(r'${work}', weekWorkKJ.toString()));
      } else {
        analysis.writeln("📊 本周总容量 ${weekWorkKJ} 千焦。");
      }
    }
    
    final weekPartsSet = <String>{};
    for (var record in records) {
      if (record.date.isAfter(startOfWeekDate) && record.date.isBefore(endOfWeekDate.add(const Duration(days: 1)))) {
        for (var p in record.projects) {
          weekPartsSet.add(p.part);
        }
      }
    }
    final weekParts = weekPartsSet.toList();
    final weekMissing = ['胸', '背', '腿', '肩', '腹'].where((p) => !weekParts.contains(p)).toList();
    if (_rulesLoaded && _coachRules.containsKey('week_part_advice')) {
      if (weekMissing.isEmpty) {
        final responses = (_coachRules['week_part_advice']['complete'] as List).cast<String>();
        analysis.writeln(_randomSelect(responses));
      } else {
        final responses = (_coachRules['week_part_advice']['missing'] as List).cast<String>();
        analysis.writeln(_randomSelect(responses).replaceAll(r'${parts}', weekMissing.join('、')));
      }
    } else {
      if (weekMissing.isNotEmpty) {
        analysis.writeln("⚠️ 本周缺少 ${weekMissing.join('、')} 的训练，下周注意平衡。");
      } else {
        analysis.writeln("✅ 本周训练部位覆盖全面！");
      }
    }
    analysis.writeln();

    // ========== 3. 整体回顾 ==========
    final totalWorkKJ = (totalWork / 1000).toInt();
    final calories = (totalWork / 4184).toInt();

    // 构建各部位详情：次数，组数，做功(千焦)
    final partSetDetails = partCount.entries.map((entry) {
      final part = entry.key;
      final count = entry.value;                      // 训练次数
      final sets = partSets[part] ?? 0;               // 总组数
      final volume = partVolume[part]!;
      final volumeKJ = (volume / 1000).toInt();
      return '$part:${count}次，${sets}组(${volumeKJ}千焦)';
    }).join('，');

    // 各部位消耗热量（大卡）
    final partCaloriesDetails = partCount.entries.map((entry) {
      final part = entry.key;
      final volume = partVolume[part]!;
      final partCal = (volume / 4184).toInt();
      return '$part:${partCal}大卡';
    }).join('，');

    analysis.writeln("🏆 健身以来整体回顾 (共 $totalSessions 次训练)：");
    analysis.writeln("📜 从开始到现在，你一共完成了 $totalSessions 次训练，${totalSets}组动作（$partSetDetails），输出 $totalWorkKJ 千焦，消耗约 $calories 大卡热量（$partCaloriesDetails）。");
    
    if (partCount.isNotEmpty) {
      final favPart = partCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      String favComment = favPart == '腿' ? '勇者！' : '继续加强其他部位。';
      if (_rulesLoaded && _coachRules.containsKey('history_summary') && _coachRules['history_summary'].containsKey('fav_part')) {
        final template = _coachRules['history_summary']['fav_part'] as String;
        analysis.writeln(template.replaceAll(r'${part}', favPart).replaceAll(r'${comment}', favComment));
      } else {
        analysis.writeln("💪 你最常训练的部位是「$favPart」，$favComment");
      }
    }
    
    if (records.length >= 2) {
      // 获取第一次和最后一次记录（按日期排序）
      final sortedByDate = List<WorkoutRecord>.from(records)..sort((a, b) => a.date.compareTo(b.date));
      final firstRecord = sortedByDate.first;
      final lastRecord = sortedByDate.last;
      final firstWork = firstRecord.projects.fold(0.0, (sum, p) => sum + p.calculateWork());
      final firstKJ = (firstWork / 1000).toInt();
      final latestWork = lastRecord.projects.fold(0.0, (sum, p) => sum + p.calculateWork());
      final latestKJ = (latestWork / 1000).toInt();
      
      String compareType;
      if (latestWork > firstWork) compareType = 'improved';
      else if (latestWork < firstWork) compareType = 'declined';
      else compareType = 'same';
      
      if (_rulesLoaded && _coachRules.containsKey('history_summary') && _coachRules['history_summary'].containsKey('first_compare')) {
        final compareMap = _coachRules['history_summary']['first_compare'] as Map;
        if (compareMap.containsKey(compareType)) {
          final template = compareMap[compareType] as String;
          analysis.writeln(template
              .replaceAll(r'${firstKJ}', firstKJ.toString())
              .replaceAll(r'${diff}', (latestKJ - firstKJ).toString()));
        }
      } else {
        if (latestWork > firstWork) {
          analysis.writeln("📈 相比第一次训练（${firstKJ}千焦），最近一次容量提升了 ${latestKJ - firstKJ}千焦，进步显著！");
        } else if (latestWork < firstWork) {
          analysis.writeln("📉 相比第一次训练（${firstKJ}千焦），最近一次容量有所下降，可能是减载或状态波动。");
        } else {
          analysis.writeln("⚖️ 相比第一次训练，容量保持稳定，可以尝试突破。");
        }
      }
    }
    
    if (totalSessions % 10 == 0 && totalSessions > 0) {
      if (_rulesLoaded && _coachRules.containsKey('history_summary') && _coachRules['history_summary'].containsKey('milestone')) {
        final template = _coachRules['history_summary']['milestone'] as String;
        analysis.writeln(template.replaceAll(r'${sessions}', totalSessions.toString()));
      } else {
        analysis.writeln("🎉 恭喜完成第 $totalSessions 次训练！这是一个重要的里程碑！");
      }
    } else if (totalSessions == 1) {
      analysis.writeln("🌟 这是你的第一次记录，坚持下去！");
    }
    analysis.writeln();
    // 鼓励和建议

    if (_rulesLoaded && _coachRules.containsKey('encouragements')) {
      final encouragements = (_coachRules['encouragements'] as List).cast<String>();
      analysis.writeln(_randomSelect(encouragements));
    } else {
      analysis.writeln("✨ 每一次力竭都是成长的信号，继续加油！");
    }
    analysis.writeln();
    
    if (_rulesLoaded && _coachRules.containsKey('tips')) {
      final tips = (_coachRules['tips'] as List).cast<String>();
      analysis.writeln(_randomSelect(tips));
    } else {
      analysis.writeln("💡 练后30分钟内补充快碳+蛋白质，有助于肌肉恢复。");
    }

    setState(() {
      _aiResponse = analysis.toString();
      _isAnalyzing = false;
      _typingController?.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details),
          onTap: () => _analyzeLocally(),
          child: Stack(
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _currentImagePath.startsWith('assets/')
                        ? AssetImage(_currentImagePath) as ImageProvider
                        : FileImage(File(_currentImagePath)),
                    fit: BoxFit.contain,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              if (_isAnalyzing)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SpinKitRing(
                      color: Theme.of(context).primaryColor,
                      size: 24,
                      lineWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_displayedResponse.isNotEmpty)
          Stack(
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _displayedResponse,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              if (_showScrollIndicator)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: AnimatedBuilder(
                    animation: _bounceController!,
                    builder: (context, child) {
                      final bounceValue = 1.0 + (_bounceController!.value * 0.15);
                      return Transform.scale(
                        scale: bounceValue,
                        child: GestureDetector(
                          onTap: () {
                            if (_isAtBottom) {
                              _scrollToTop();
                            } else {
                              _scrollToBottom();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isAtBottom ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        if (!_isAnalyzing && _displayedResponse.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '👆 单击形象获取训练分析\n👇 右键更换陪练形象',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}