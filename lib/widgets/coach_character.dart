import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CoachCharacter extends StatefulWidget {
  final List<dynamic> records;
  const CoachCharacter({super.key, required this.records});

  @override
  State<CoachCharacter> createState() => _CoachCharacterState();
}

class _CoachCharacterState extends State<CoachCharacter> with TickerProviderStateMixin {
  // ---------- 陪练形象 ----------
  String _currentImagePath = 'assets/吉祥物奔奔猫.gif';
  List<String> _presetImages = [];

  // ---------- 分析状态 ----------
  bool _isAnalyzing = false;
  String _aiResponse = '';
  String _displayedResponse = '';
  AnimationController? _typingController;

  // ---------- 滚动控制 ----------
  final ScrollController _scrollController = ScrollController();
  AnimationController? _bounceController;
  bool _isAtBottom = true;
  bool _showScrollIndicator = false;

  // ---------- 智能分析引擎 ----------
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
    try {
      final testSpan = TextSpan(text: text);
      return text;
    } catch (e) {
      return text.replaceAll(RegExp(r'[^\x00-\x7F\u4e00-\u9fff\u3000-\u303f\uff00-\uffef\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+', unicode: true), '');
    }
  }

  @override
  void dispose() {
    _typingController?.dispose();
    _bounceController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ---------- 加载规则文件 ----------
  Future<void> _loadCoachRules() async {
    try {
      final String data = await rootBundle.loadString('assets/coach_rules.json');
      setState(() {
        _coachRules = json.decode(data);
        _rulesLoaded = true;
      });
    } catch (e) {
      print('加载规则文件失败: $e');
      _coachRules = {};
    }
  }

  // ---------- 图片预设管理 ----------
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

  // ---------- 随机选择 ----------
  String _randomSelect(List<String> list) {
    if (list.isEmpty) return '';
    final random = Random();
    return list[random.nextInt(list.length)];
  }

  // ---------- 线性回归预测 ----------
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

  // ---------- 更换形象菜单 ----------
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

  // ---------- 右键菜单 ----------
  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & (overlay?.paintBounds.size ?? Size.zero),
      ),
      items: [
        const PopupMenuItem(value: 'changeImage', child: Text('🎨 更改陪练形象')),
        const PopupMenuItem(value: 'analyze', child: Text('📊 分析训练数据')),
      ],
    ).then((value) {
      if (value == 'changeImage') {
        _showChangeImageMenu();
      } else if (value == 'analyze') {
        _analyzeLocally();
      }
    });
  }

  // ---------- 本地分析引擎（升级版）----------
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

    // 收集数据
    int totalSessions = records.length;
    
    // 本周统计
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

    // 部位统计
    Map<String, int> partCount = {};
    Map<String, double> partVolume = {};
    double totalWork = 0;
    int totalSets = 0;
    List<Map<String, dynamic>> recentProjects = [];
    _exerciseHistory = [];

    for (var record in records) {
      for (var project in record.projects) {
        if (project.name.isEmpty) continue;
        
        totalWork += (project.calculateWork() as num).toDouble();
        totalSets += (project.sets as int);
        partCount[project.part] = (partCount[project.part] ?? 0) + 1;
        partVolume[project.part] = (partVolume[project.part] ?? 0) + (project.calculateWork() as num).toDouble();

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

    // 构建分析
    StringBuffer analysis = StringBuffer();
    
    // 开场
    if (_rulesLoaded && _coachRules.containsKey('openings')) {
      final openings = (_coachRules['openings'] as List).cast<String>();
      analysis.writeln(_randomSelect(openings));
    } else {
      analysis.writeln("🔍 让我看看你的训练数据～");
    }
    analysis.writeln();

    // 总次数
    analysis.writeln("📋 目前你一共进行了 $totalSessions 次健身训练。");
    
    // 里程碑
    if (totalSessions % 10 == 0 && _rulesLoaded && _coachRules.containsKey('milestones')) {
      final milestones = (_coachRules['milestones'] as List).cast<String>();
      final msg = _randomSelect(milestones).replaceAll(r'${sessions}', totalSessions.toString());
      analysis.writeln(msg);
    }
    analysis.writeln();

    // 本周频率
    analysis.writeln("📅 本周（$weekRange）训练统计：");
    String freqLevel;
    if (thisWeekSessions >= 5) freqLevel = 'excellent';
    else if (thisWeekSessions >= 3) freqLevel = 'good';
    else if (thisWeekSessions >= 1) freqLevel = 'fair';
    else freqLevel = 'poor';
    
    if (_rulesLoaded && _coachRules.containsKey('frequency_responses')) {
      final responses = (_coachRules['frequency_responses'][freqLevel] as List).cast<String>();
      final msg = _randomSelect(responses).replaceAll(r'${sessions}', thisWeekSessions.toString());
      analysis.writeln(msg);
    } else {
      // 降级方案
      if (thisWeekSessions >= 5) {
        analysis.writeln("🔥 本周训练频率非常棒！已经进行了 $thisWeekSessions 次训练！");
      } else if (thisWeekSessions >= 3) {
        analysis.writeln("👍 本周进行了 $thisWeekSessions 次训练，频率不错。");
      } else if (thisWeekSessions >= 1) {
        analysis.writeln("📌 本周进行了 $thisWeekSessions 次训练，可以试着增加到每周3次以上。");
      } else {
        analysis.writeln("⏰ 本周还没有训练记录，别忘了抽时间去锻炼哦！");
      }
    }
    
    // 容量分析
    if (thisWeekSessions > 0 && _rulesLoaded && _coachRules.containsKey('volume_analysis')) {
      String volumeLevel;
      if (thisWeekVolume > 50000) volumeLevel = 'high';
      else if (thisWeekVolume > 20000) volumeLevel = 'moderate';
      else volumeLevel = 'low';
      
      final responses = (_coachRules['volume_analysis'][volumeLevel] as List).cast<String>();
      analysis.writeln(_randomSelect(responses));
    }
    analysis.writeln();

    // 部位分析
    if (partCount.isNotEmpty) {
      String mainPart = partCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      List<String> missingParts = ['胸', '背', '腿', '肩'].where((p) => !partCount.containsKey(p)).toList();
      
      analysis.writeln("🎯 训练部位分析：");
      partCount.forEach((part, count) {
        analysis.writeln("  • $part：训练 $count 次，总做功 ${(partVolume[part]! / 1000).toStringAsFixed(1)} 千焦");
      });
      analysis.writeln();
      
      if (_rulesLoaded && _coachRules.containsKey('part_balance')) {
        if (missingParts.isEmpty) {
          final responses = (_coachRules['part_balance']['complete'] as List).cast<String>();
          analysis.writeln(_randomSelect(responses));
        } else {
          final responses = (_coachRules['part_balance']['missing'] as List).cast<String>();
          final msg = _randomSelect(responses).replaceAll(r'${parts}', missingParts.join('、'));
          analysis.writeln(msg);
        }
      } else {
        if (missingParts.isNotEmpty) {
          analysis.writeln("⚠️ 我注意到你还没有训练过${missingParts.join('、')}，记得全面发展。");
        } else {
          analysis.writeln("✅ 训练部位覆盖全面，当前侧重部位是「$mainPart」。");
        }
      }
    }
    analysis.writeln();

    // 进步追踪 + 预测
    if (recentProjects.length >= 2) {
      var latest = recentProjects.first;
      var previous = recentProjects.skip(1).firstWhere(
          (p) => p['name'] == latest['name'] && p['part'] == latest['part'],
          orElse: () => <String, dynamic>{});
      
      if (previous.isNotEmpty) {
        double weightDiff = (latest['weight'] as num).toDouble() - (previous['weight'] as num).toDouble();
        analysis.writeln("📈 进步追踪：");
        
        String progressType;
        if (weightDiff > 0) progressType = 'improved';
        else if (weightDiff < 0) progressType = 'declined';
        else progressType = 'same';
        
        if (_rulesLoaded && _coachRules.containsKey('progress_tracking')) {
          final responses = (_coachRules['progress_tracking'][progressType] as List).cast<String>();
          var msg = _randomSelect(responses)
              .replaceAll(r'${name}', latest['name'].toString())
              .replaceAll(r'${diff}', weightDiff.abs().toStringAsFixed(1));
          analysis.writeln("  • $msg");
        } else {
          if (weightDiff > 0) {
            analysis.writeln("  • 动作「${latest['name']}」的重量比上次提升了 ${weightDiff.toStringAsFixed(1)} kg！");
          } else if (weightDiff < 0) {
            analysis.writeln("  • 「${latest['name']}」的重量略有下降，可能是状态波动。");
          } else {
            analysis.writeln("  • 「${latest['name']}」的重量与上次持平。");
          }
        }
        
        // 线性回归预测
        final predicted = _predictNextWeight(latest['name'] as String, latest['part'] as String);
        if (predicted != null && _rulesLoaded && _coachRules.containsKey('predictions')) {
          final templates = (_coachRules['predictions']['templates'] as List).cast<String>();
          final currentWeight = (latest['weight'] as num).toDouble();
          final weeks = ((predicted - currentWeight) / (weightDiff.abs() + 0.1)).abs().ceil().clamp(2, 12);
          final target = currentWeight + (predicted - currentWeight) / 2;
          var msg = _randomSelect(templates)
              .replaceAll(r'${name}', latest['name'].toString())
              .replaceAll(r'${weeks}', weeks.toString())
              .replaceAll(r'${target}', target.toStringAsFixed(1));
          analysis.writeln("  • $msg");
        }
      }
    }
    analysis.writeln();

    // 总结
    analysis.writeln("💪 累计数据统计：");
    analysis.writeln("  • 总训练次数：$totalSessions 次");
    analysis.writeln("  • 总做功：${(totalWork / 1000).toStringAsFixed(0)} 千焦");
    analysis.writeln("  • 总组数：$totalSets 组");
    analysis.writeln("  • 消耗热量：约 ${(totalWork / 4184).toStringAsFixed(0)} 大卡");
    analysis.writeln();

    // 鼓励语
    if (_rulesLoaded && _coachRules.containsKey('encouragements')) {
      final encouragements = (_coachRules['encouragements'] as List).cast<String>();
      analysis.writeln(_randomSelect(encouragements));
    } else {
      analysis.writeln("✨ 每一次力竭都是成长的信号，继续加油！");
    }
    analysis.writeln();

    // 小贴士
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
                          color: Colors.black.withOpacity(0.1),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                              color: Theme.of(context).primaryColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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