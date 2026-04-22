import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart' as xml;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class KnowledgeUpdateService {
  static const String jsonFileName = 'coach_rules.json';
  static const String entrezEmail = 'Ethocas@outlook.com';

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

  // ========== 扩展的抓取源 ==========
  static const List<String> quoteSources = [
    "https://www.bodybuilding.com/fun/88-motivational-quotes-for-bodybuilders.html",
    "https://www.greatist.com/fitness/fitness-quotes",
    "https://www.muscleandfitness.com/flexpress/fitness-quotes/",
    "https://www.verywellfit.com/best-fitness-quotes-5114038",
    "https://www.healthline.com/health/fitness-exercise/fitness-quotes",
    "https://www.shape.com/fitness/tips/fitness-quotes",
    "https://www.eatthis.com/fitness-quotes/",
    "https://www.prevention.com/fitness/a20451935/motivational-fitness-quotes/",
    "https://www.self.com/story/fitness-quotes",
    "https://www.rd.com/list/fitness-quotes/",
    "https://www.briantracy.com/blog/personal-success/motivational-fitness-quotes/",
    "https://www.keepinspiring.me/fitness-quotes/",
    "https://www.thelawofattraction.com/fitness-quotes/",
    "https://www.goalcast.com/fitness-quotes/",
    "https://www.everydaypower.com/fitness-quotes/",
    "https://www.powerofpositivity.com/fitness-quotes/",
    "https://www.lifehack.org/articles/lifestyle/50-fitness-quotes-that-will-inspire-you-to-workout.html",
    "https://www.brainyquote.com/topics/fitness-quotes",
    "https://www.quotescover.com/topic/fitness",
    "https://www.wiseoldsayings.com/fitness-quotes/",
    "https://www.inspiringquotes.us/topic/fitness",
    "https://www.azquotes.com/quotes/topics/fitness.html",
    "https://www.quotegarden.com/fitness.html",
    "https://www.quotehd.com/quotes/topics/fitness",
    "https://www.quoteswave.com/topic/fitness",
    'https://www.acefitness.org/education-and-resources/lifestyle/blog/6730/debunking-common-fitness-myths/',
    'https://www.healthline.com/nutrition/20-fitness-myths',
    'https://www.verywellfit.com/common-fitness-myths-1229814',
    'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/fitness-myths/art-20047099',
    'https://www.webmd.com/fitness-exercise/ss/slideshow-fitness-myths',
    'https://www.self.com/story/fitness-myths-debunked',
    'https://www.shape.com/fitness/tips/fitness-myths-debunked',
    'https://www.prevention.com/fitness/a20451935/fitness-myths/',
    'https://www.rd.com/list/fitness-myths/',
    'https://www.eatthis.com/fitness-myths/',
    'https://www.lifehack.org/articles/lifestyle/10-fitness-myths-you-need-to-stop-believing.html',
    'https://www.bodybuilding.com/content/10-fitness-myths-debunked.html',
    'https://www.muscleandfitness.com/workouts/workout-tips/10-fitness-myths-busted/',
    'https://www.greatist.com/fitness/common-fitness-myths',
    'https://www.health.com/fitness/fitness-myths',
    'https://www.thehealthy.com/exercise/fitness-myths/',
    'https://www.livestrong.com/article/13725598-fitness-myths-debunked/',
    'https://www.acefitness.org/education-and-resources/lifestyle/blog/6593/7-strength-training-protocols-for-muscle-growth/',
    'https://www.healthline.com/health/fitness-exercise/strength-training-routines',
    'https://www.verywellfit.com/best-strength-training-workouts-4154676',
    'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/strength-training/art-20046670',
    'https://www.webmd.com/fitness-exercise/ss/slideshow-strength-training-basics',
    'https://www.self.com/story/best-strength-training-workouts',
    'https://www.shape.com/fitness/workouts/best-workout-routines',
    'https://www.prevention.com/fitness/workouts/a20451935/best-workout-plans/',
    'https://www.rd.com/list/best-exercise-routines/',
    'https://www.eatthis.com/best-workout-routines/',
    'https://www.lifehack.org/articles/lifestyle/10-best-workout-routines-for-men-and-women.html',
    'https://www.bodybuilding.com/content/10-best-muscle-building-workout-routines.html',
    'https://www.muscleandfitness.com/workouts/workout-routines/',
    'https://www.greatist.com/fitness/best-workout-routines',
    'https://www.health.com/fitness/best-workout-plans',
    'https://www.thehealthy.com/exercise/best-workout-routines/',
    'https://www.livestrong.com/article/13725599-best-workout-routines/',
  ];
  static const List<String> chineseKeywords = [
    '运动营养', '力量训练 研究', '肌肉增长 科学', '高强度间歇训练 效果',
    '健身 误区', '运动恢复 最新', '抗阻训练 进展', '健身 科学研究',
    '增肌 方法', '减脂 科学', '有氧运动 益处', '核心训练 原理',
    '拉伸 重要性', '健身 饮食', '补剂 研究', '训练计划 设计',
    '女性 健身', '老年人 力量训练', '青少年 运动', '运动损伤 预防',
    '健身 心理学', '睡眠 与 运动恢复', 'HIIT 研究', '瑜伽 健康',
    '普拉提 好处', 'CrossFit 研究', '健美 营养', '跑步 健康',
    '游泳 健身', '骑行 锻炼', '登山 体力', '跳绳 燃脂',
    'Tabata 效果', '功能性训练', '平衡训练', '柔韧性 训练',
    '爆发力 训练', '速度 训练', '敏捷性 训练', '耐力 训练',
  ];

  static const List<String> arxivQueries = [
    'strength training', 'muscle hypertrophy', 'exercise physiology',
    'sports nutrition', 'resistance training', 'endurance exercise',
    'protein metabolism', 'creatine supplementation', 'concurrent training',
    'periodization', 'plyometric training', 'blood flow restriction',
    'recovery modalities', 'sleep and athletic performance', 'caffeine performance',
    'beta alanine', 'citrulline malate', 'HMB supplementation',
    'vitamin D athletic performance', 'omega 3 exercise', 'probiotics athlete',
    'intermittent fasting exercise', 'ketogenic diet performance', 'vegan athlete',
    'female athlete triad', 'youth resistance training', 'master athlete',
    'tendon adaptation', 'bone density exercise', 'sarcopenia prevention',
  ];

  static const List<String> pubmedQueries = [
    'resistance training muscle hypertrophy',
    'protein intake muscle protein synthesis',
    'high intensity interval training cardiovascular health',
    'creatine supplementation strength',
    'beta alanine exercise performance',
    'caffeine ergogenic aid',
    'concurrent training interference',
    'stretching injury prevention',
    'foam rolling recovery',
    'sleep deprivation athletic performance',
    'menstrual cycle exercise performance',
    'aging sarcopenia resistance exercise',
    'obesity exercise intervention',
    'type 2 diabetes resistance training',
    'hypertension aerobic exercise',
    'depression physical activity',
    'bone density weight bearing exercise',
    'tendinopathy rehabilitation',
    'ACL injury prevention',
    'probiotics immune function athlete',
    'vitamin D muscle strength',
    'omega 3 fatty acid inflammation exercise',
    'citrulline malate fatigue',
    'HMB muscle damage',
    'sodium bicarbonate buffering capacity',
    'nitrate supplementation endurance',
    'carbohydrate mouth rinse performance',
    'cold water immersion recovery',
    'compression garments muscle soreness',
    'high intensity interval training health',
    'strength training elderly',
    'nutrition recovery exercise',
  ];

  static const List<String> blacklist = [
    "click here", "buy now", "discount", "miracle", "guaranteed", "ad", "sponsored",
    "promotion", "sale", "limited time", "exclusive", "new release", "affiliate",
    "advertisement", "产品", "促销", "代理", "点击", "购买", "优惠", "神奇", "保证",
    "广告", "赞助", "影视剧", "小说", "漫画", "游戏", "娱乐", "八卦", "明星", "网红",
    "测评", "推荐", "选购", "百度百科", "辭典", "檢視", "康复", "字典", "释义", "意思",
    "是什么", "怎么吃", "方法", "步骤", "教程", "指南", "方案", "计划", "excellent",
    "amazing", "incredible", "unbelievable", "best", "worst", "top", "review",
    "comparison", "评测", "对比", "排行榜", "最佳", "最差", "神评", "张雪峰", "免费",
    "免费试用", "试用装", "限时", "限量", "独家", "首发", "新品", "开箱", "开箱视频",
    "开箱测评", "娱乐圈", "影视圈", "明星八卦", "网红八卦", "娱乐八卦", "影视八卦",
    "京东", "好物", "畅游", "运动户外", "特价", "秒杀", "包邮", "满减", "领券",
    "优惠券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一", "热卖", "爆款",
    "销量第一", "好评如潮", "口碑爆棚", "正品保障", "假一赔十", "七天无理由",
    "运费险", "极速退款", "闪电发货", "会员专享", "VIP特价", "黑卡会员", "钻石会员",
    "超级会员", "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "维生素", "益生菌",
    "鱼油", "红牛", "魔爪", "东鹏特饮", "乐虎", "战马", "康比特", "诺特兰德", "肌肉科技",
    "GNC", "健安喜", "汤臣倍健", "速看", "慎入", "深度好文", "必读", "收藏", "转发",
    "扩散", "感恩", "感动", "泪目", "揭秘", "内幕", "潜藏", "隐藏", "不为人知", "惊人",
    "震惊", "GitHub", "研发", "意义", "服务", "怎么样", "最新", "股價", "走勢", "社群",
    "股市", "登录", "用户", "引擎", "巨量", "抖音", "营销", "zhihu", "知乎", "理財",
    "理财", "資料", "股份", "资料", "上市", "高三", "瑞文", "测试", "百度知道", "360问答",
    "搜狗问问", "新浪爱问", "腾讯问问", "网易知道", "问答", "提问", "回答", "问题",
    "答案", "解答", "咨询", "客服", "教程", "教学", "课程", "培训", "学习", "教育",
    "视频", "直播", "讲座", "研讨会", "会议", "论坛", "社区", "贴吧", "群", "微信群",
    "QQ群", "公众号", "小红书", "快手", "B站", "哔哩哔哩", "微博", "微信", "Instagram",
    "Facebook", "Twitter", "LinkedIn", "YouTube", "TikTok", "Snapchat", "Reddit",
    "Pinterest", "康复", "字典", "意思", "怎么吃", "方法", "步骤", "教程", "指南",
    "方案", "计划", "评测", "对比", "排行榜", "最佳", "最差", "神评", "免费", "试用",
    "限时", "限量", "独家", "首发", "新品", "开箱", "娱乐圈", "明星八卦", "网红八卦",
    "娱乐八卦", "影视八卦", "京东", "好物", "畅游", "运动户外", "特价", "秒杀", "包邮",
    "满减", "领券", "优惠券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一",
    "热卖", "爆款", "销量第一", "好评如潮", "口碑爆棚", "正品保障", "假一赔十",
    "七天无理由", "运费险", "极速退款", "闪电发货", "会员专享", "VIP特价", "黑卡会员",
    "钻石会员", "超级会员", "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "维生素",
    "益生菌", "鱼油", "红牛", "魔爪", "东鹏特饮", "乐虎", "战马", "康比特", "诺特兰德",
    "肌肉科技", "GNC", "健安喜", "汤臣倍健", "速看", "慎入", "深度好文", "必读", "收藏",
    "转发", "扩散", "感恩", "感动", "泪目", "揭秘", "内幕", "潜藏", "隐藏", "不为人知",
    "惊人", "震惊", "GitHub", "研发", "意义", "服务", "怎么样", "最新", "股價", "走勢",
    "社群", "股市", "登录", "用户", "引擎", "巨量", "抖音", "营销", "zhihu", "知乎",
    "理財", "理财", "資料", "股份", "资料", "上市", "高三", "瑞文", "测试", "百度知道",
    "360问答", "搜狗问问", "新浪爱问", "腾讯问问", "网易知道", "问答", "提问", "回答",
    "问题", "答案", "解答", "咨询", "客服", "教程", "教学", "课程", "培训", "学习",
    "教育", "视频", "直播", "讲座", "研讨会", "会议", "论坛", "社区", "贴吧", "群",
    "微信群", "QQ群", "公众号", "小红书", "快手", "B站", "哔哩哔哩", "微博", "微信",
    "Instagram", "Facebook", "Twitter", "LinkedIn", "YouTube", "TikTok", "Snapchat",
    "Reddit", "Pinterest",
  ];
  // ========== 主更新流程（改为顺序执行，避免并发超时） ==========
  static Future<bool> runUpdate() async {
    print('📡 开始知识库更新流程...');
    try {
      final jsonFile = await _getJsonFile();
      Map<String, dynamic> data = await _loadJson(jsonFile);
      final beforeStats = _getStatsFromData(data);
      print('更新前: $beforeStats');

      // 顺序执行抓取，避免并发导致超时
      final newResearch = await _fetchWithFallback(_fetchAllResearch, _getPresetResearch, '研究');
      final newEncouragements = await _fetchWithFallback(_fetchAllEncouragements, _getPresetEncouragements, '鼓励语');
      final newTips = await _fetchWithFallback(_fetchAllTips, _getPresetTips, '小贴士');
      final newFacts = await _fetchWithFallback(_fetchAllFacts, _getPresetFacts, '科学事实');
      final newMyths = await _fetchWithFallback(_fetchMyths, _getPresetMyths, '迷思');
      final newProtocols = await _fetchWithFallback(_fetchProtocols, _getPresetProtocols, '方案');

      print('抓取结果: 研究${newResearch.length} 鼓励${newEncouragements.length} 提示${newTips.length} 事实${newFacts.length} 迷思${newMyths.length} 方案${newProtocols.length}');

      data = _mergeAndLog(data, 'research_summaries', newResearch);
      data = _mergeAndLog(data, 'encouragements', newEncouragements);
      data = _mergeAndLog(data, 'tips', newTips);
      data = _mergeAndLog(data, 'scientific_facts', newFacts);
      data = _mergeAndLog(data, 'myth_busters', newMyths);
      data = _mergeAndLog(data, 'training_protocols', newProtocols);

      data = _cleanBlacklisted(data);
      await _saveJson(jsonFile, data);

      final afterStats = _getStatsFromData(data);
      print('更新后: $afterStats');
      print('🎉 知识库更新完成！');
      return true;
    } catch (e) {
      print('❌ 知识库更新失败: $e');
      return false;
    }
  }

  // ========== 聚合抓取方法（增加超时和重试） ==========
  static Future<List<String>> _fetchAllResearch() async {
    final arxiv = await _safeFetch(_fetchArxivResearch, 'arXiv', timeoutSec: 35);
    final pubmed = await _safeFetch(_fetchPubMedSummaries, 'PubMed', timeoutSec: 35);
    final rss = await _safeFetch(_fetchScienceDailyRss, 'ScienceDaily', timeoutSec: 35);
    return [...arxiv, ...pubmed, ...rss];
  }

  static Future<List<String>> _fetchAllEncouragements() async {
    final fromWeb = await _safeFetch(_fetchEncouragementsFromWeb, '名言网站', timeoutSec: 45);
    return [...fromWeb, ..._getPresetEncouragements()];
  }

  static Future<List<String>> _fetchAllTips() async {
    final quotes = await _safeFetch(_fetchEncouragementsFromWeb, '名言网站(小贴士)', timeoutSec: 45);
    final tipsFromQuotes = quotes
        .where((s) => s.length < 80)
        .map((s) => s.replaceFirst(RegExp(r'^💪'), '💡'))
        .toList();
    return [...tipsFromQuotes, ..._getPresetTips()];
  }

  static Future<List<String>> _fetchAllFacts() async {
    final bing = await _safeFetch(_fetchBingFacts, '必应', timeoutSec: 45);
    final baidu = await _safeFetch(_fetchBaiduFacts, '百度', timeoutSec: 45);
    final pubmed = await _safeFetch(_fetchPubMedSummaries, 'PubMed', timeoutSec: 35);
    final arxiv = await _safeFetch(_fetchArxivResearch, 'arXiv', timeoutSec: 35);
    return [...bing, ...baidu, ...pubmed, ...arxiv, ..._getPresetFacts()];
  }

  // 安全执行抓取，避免单个源崩溃
  static Future<List<String>> _safeFetch(
    Future<List<String>> Function() fetcher,
    String sourceName, {
    int timeoutSec = 35,
  }) async {
    try {
      return await fetcher().timeout(Duration(seconds: timeoutSec));
    } catch (e) {
      print('⚠️ $sourceName 抓取失败: $e');
      return [];
    }
  }

  // ========== 迷思抓取（优化重试和延迟） ==========
  static Future<List<String>> _fetchMyths() async {
    final List<String> results = [];
    final client = _createHttpClient();

    for (final url in quoteSources.take(30)) { // 限制数量，避免超时
      await Future.delayed(const Duration(milliseconds: 1200));
      try {
        final response = await _getWithRetry(client, url, retries: 2)
            .timeout(const Duration(seconds: 15));
        if (response == null || response.statusCode != 200) continue;

        final document = html_parser.parse(response.body);
        List<String> texts = [];

        // 根据网站解析（简化版，保持原逻辑）
        document.querySelectorAll('p, li, h2, h3').forEach((el) {
          final text = el.text.trim();
          if (text.toLowerCase().contains('myth') ||
              text.contains('误区') ||
              text.contains('迷思')) {
            if (text.length > 15 && text.length < 200) texts.add('🧠 $text');
          }
        });

        results.addAll(texts);
        if (results.length >= 80) break;
      } catch (e) {
        // 忽略单个URL错误
      }
    }
    client.close();

    final unique = results.toSet().take(60).toList();
    print('迷思抓取到 ${unique.length} 条');
    return [...unique, ..._getPresetMyths()];
  }

  // ========== 训练方案抓取 ==========
  static Future<List<String>> _fetchProtocols() async {
    final List<String> results = [];
    final client = _createHttpClient();

    for (final url in quoteSources.take(30)) {
      await Future.delayed(const Duration(milliseconds: 1200));
      try {
        final response = await _getWithRetry(client, url, retries: 2)
            .timeout(const Duration(seconds: 15));
        if (response == null || response.statusCode != 200) continue;

        final document = html_parser.parse(response.body);
        List<String> texts = [];

        document.querySelectorAll('p, li').forEach((el) {
          final text = el.text.trim();
          if (text.length > 30 && text.length < 200) texts.add('🏋️ $text');
        });

        results.addAll(texts);
        if (results.length >= 80) break;
      } catch (e) {
        // 忽略错误
      }
    }
    client.close();

    final unique = results.toSet().take(60).toList();
    print('训练方案抓取到 ${unique.length} 条');
    return [...unique, ..._getPresetProtocols()];
  }

  // ========== PubMed 抓取 ==========
  static Future<List<String>> _fetchPubMedSummaries() async {
    final List<String> results = [];
    final client = _createHttpClient();
    try {
      for (final query in pubmedQueries.take(10)) { // 减少查询数量
        await Future.delayed(const Duration(seconds: 2));
        final searchUrl = Uri.https('eutils.ncbi.nlm.nih.gov', '/entrez/eutils/esearch.fcgi', {
          'db': 'pubmed',
          'term': query,
          'retmax': '2',
          'retmode': 'json',
          'email': entrezEmail,
        });
        final searchResp = await _getWithRetry(client, searchUrl.toString(), isUri: true, uri: searchUrl, retries: 2)
            .timeout(const Duration(seconds: 25));
        if (searchResp == null || searchResp.statusCode != 200) continue;

        final searchData = json.decode(searchResp.body);
        final idList = (searchData['esearchresult']['idlist'] as List?)?.cast<String>() ?? [];
        if (idList.isEmpty) continue;

        final fetchUrl = Uri.https('eutils.ncbi.nlm.nih.gov', '/entrez/eutils/efetch.fcgi', {
          'db': 'pubmed',
          'id': idList.join(','),
          'retmode': 'xml',
          'email': entrezEmail,
        });
        final fetchResp = await _getWithRetry(client, fetchUrl.toString(), isUri: true, uri: fetchUrl, retries: 2)
            .timeout(const Duration(seconds: 25));
        if (fetchResp == null || fetchResp.statusCode != 200) continue;

        final document = xml.XmlDocument.parse(fetchResp.body);
        final articles = document.findAllElements('PubmedArticle');
        for (final article in articles) {
          final title = article.findAllElements('ArticleTitle').firstOrNull?.innerText ?? '';
          final abstract = article.findAllElements('AbstractText').map((e) => e.innerText).join(' ');
          if (title.isNotEmpty && abstract.isNotEmpty) {
            final combined = '$title. $abstract'.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (combined.length > 50 && combined.length < 600) {
              results.add('🔬 $combined');
            }
          }
        }
      }
    } catch (e) {
      print('PubMed 抓取异常: $e');
    } finally {
      client.close();
    }
    print('PubMed 返回 ${results.length} 条');
    return results.toSet().toList();
  }

  // ========== arXiv 抓取 ==========
  static Future<List<String>> _fetchArxivResearch() async {
    final List<String> results = [];
    final client = _createHttpClient();
    try {
      for (final query in arxivQueries.take(10)) {
        await Future.delayed(const Duration(seconds: 2));
        final url = Uri.parse('http://export.arxiv.org/api/query?search_query=all:$query&start=0&max_results=1');
        final response = await _getWithRetry(client, url.toString(), isUri: true, uri: url, retries: 2)
            .timeout(const Duration(seconds: 20));
        if (response == null || response.statusCode != 200) continue;

        final document = xml.XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');
        for (final entry in entries) {
          final title = entry.findElements('title').firstOrNull?.innerText?.replaceAll('\n', ' ')?.trim() ?? '';
          final summary = entry.findElements('summary').firstOrNull?.innerText?.replaceAll('\n', ' ')?.trim() ?? '';
          if (title.isEmpty || summary.isEmpty) continue;
          String cleanSummary = summary.length > 200 ? '${summary.substring(0, 200)}...' : summary;
          results.add('🔬 $title: $cleanSummary');
        }
      }
    } catch (e) {
      print('arXiv 抓取异常: $e');
    } finally {
      client.close();
    }
    return results.toSet().toList();
  }

  // ========== ScienceDaily RSS ==========
  static Future<List<String>> _fetchScienceDailyRss() async {
    final List<String> results = [];
    try {
      final url = Uri.parse('https://www.sciencedaily.com/rss/health_medicine/fitness.xml');
      final response = await _getWithRetry(_createHttpClient(), url.toString(), isUri: true, uri: url)
          .timeout(const Duration(seconds: 20));
      if (response == null || response.statusCode != 200) return [];

      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      for (final item in items.take(10)) {
        final title = item.findElements('title').firstOrNull?.innerText ?? '';
        final desc = item.findElements('description').firstOrNull?.innerText ?? '';
        if (title.isNotEmpty && desc.isNotEmpty) {
          final cleanDesc = desc.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ').trim();
          final combined = '$title. $cleanDesc';
          if (combined.length > 50 && combined.length < 500) results.add('📰 $combined');
        }
      }
    } catch (e) {
      print('ScienceDaily RSS 失败: $e');
    }
    return results;
  }

  // ========== 必应搜索 ==========
  static Future<List<String>> _fetchBingFacts() async {
    final List<String> results = [];
    final client = _createHttpClient();
    for (final keyword in chineseKeywords.take(15)) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final url = Uri.parse('https://www.bing.com/search?q=${Uri.encodeComponent(keyword)}&count=2');
        final response = await _getWithRetry(client, url.toString(), isUri: true, uri: url, retries: 2)
            .timeout(const Duration(seconds: 15));
        if (response == null || response.statusCode != 200) continue;

        final document = html_parser.parse(response.body);
        document.querySelectorAll('.b_caption p').forEach((el) {
          String text = el.text.trim();
          if (text.length > 40 && text.length < 300) results.add('📚 $text');
        });
      } catch (e) {
        /* ignore */
      }
    }
    client.close();
    return results.toSet().toList();
  }

  // ========== 百度搜索 ==========
  static Future<List<String>> _fetchBaiduFacts() async {
    final List<String> results = [];
    final client = _createHttpClient();
    for (final keyword in chineseKeywords.take(15)) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final url = Uri.parse('https://www.baidu.com/s?wd=${Uri.encodeComponent(keyword)}&rn=2');
        final response = await _getWithRetry(client, url.toString(), isUri: true, uri: url, retries: 2)
            .timeout(const Duration(seconds: 15));
        if (response == null || response.statusCode != 200) continue;

        final document = html_parser.parse(response.body);
        document.querySelectorAll('.c-abstract').forEach((el) {
          String text = el.text.trim();
          if (text.length > 40 && text.length < 300) results.add('📚 $text');
        });
      } catch (e) {
        /* ignore */
      }
    }
    client.close();
    return results.toSet().toList();
  }

  // ========== 名言网站抓取 ==========
  static Future<List<String>> _fetchEncouragementsFromWeb() async {
    final List<String> results = [];
    final client = _createHttpClient();
    for (final url in quoteSources.take(30)) {
      await Future.delayed(const Duration(milliseconds: 800));
      try {
        final response = await _getWithRetry(client, url, retries: 2).timeout(const Duration(seconds: 12));
        if (response == null || response.statusCode != 200) continue;

        final document = html_parser.parse(response.body);
        final elements = document.querySelectorAll('li, p, blockquote, .quote, .quote-text');
        for (final el in elements) {
          String text = el.text.trim();
          if (text.length > 15 && text.length < 200 && !_containsBlacklisted(text)) {
            results.add('💪 $text');
          }
        }
        if (results.length >= 100) break;
      } catch (e) {
        /* ignore */
      }
    }
    client.close();
    return results.toSet().toList();
  }

  // ========== 辅助：带降级的抓取 ==========
  static Future<List<String>> _fetchWithFallback(
    Future<List<String>> Function() fetcher,
    List<String> Function() fallback,
    String name,
  ) async {
    try {
      final result = await fetcher().timeout(const Duration(seconds: 60));
      if (result.isNotEmpty) return result;
      print('⚠️ $name 抓取为空，使用预设');
      return fallback();
    } catch (e) {
      print('⚠️ $name 抓取失败: $e，使用预设');
      return fallback();
    }
  }

  // ========== HTTP 辅助函数 ==========
  static http.Client _createHttpClient() => http.Client();

  static Future<http.Response?> _getWithRetry(http.Client client, String url,
      {int retries = 2, bool isUri = false, Uri? uri}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final requestUri = isUri ? uri! : Uri.parse(url);
        final response = await client.get(requestUri, headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
        });
        return response;
      } catch (e) {
        if (i == retries) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    return null;
  }

  // ========== 合并与日志 ==========
  static Map<String, dynamic> _mergeAndLog(
      Map<String, dynamic> data, String category, List<String> newEntries) {
    if (!data.containsKey(category)) data[category] = [];
    final oldSet = Set<String>.from(data[category].whereType<String>());
    int added = 0;
    for (final entry in newEntries) {
      if (entry.isNotEmpty && !oldSet.contains(entry)) {
        data[category].add(entry);
        oldSet.add(entry);
        added++;
      }
    }
    if (added > 0) print('   ➕ $category 新增 $added 条');
    return data;
  }

  static Map<String, int> _getStatsFromData(Map<String, dynamic> data) {
    return {
      '研究': (data['research_summaries'] as List?)?.length ?? 0,
      '鼓励': (data['encouragements'] as List?)?.length ?? 0,
      '提示': (data['tips'] as List?)?.length ?? 0,
      '事实': (data['scientific_facts'] as List?)?.length ?? 0,
      '迷思': (data['myth_busters'] as List?)?.length ?? 0,
      '方案': (data['training_protocols'] as List?)?.length ?? 0,
    };
  }

  // ========== 文件操作 ==========
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

  static Map<String, dynamic> _cleanBlacklisted(Map<String, dynamic> data) {
    final categories = [
      'scientific_facts',
      'research_summaries',
      'myth_busters',
      'training_protocols',
      'tips',
      'encouragements'
    ];
    for (final cat in categories) {
      if (data.containsKey(cat) && data[cat] is List) {
        final list = List<String>.from(data[cat]);
        final filtered = list.where((text) => !_containsBlacklisted(text)).toList();
        data[cat] = filtered;
      }
    }
    return data;
  }

  static bool _containsBlacklisted(String text) {
    final lower = text.toLowerCase();
    return blacklist.any((kw) => lower.contains(kw.toLowerCase()));
  }

  // ========== 预设内容（静态常量，避免重复生成） ==========
  static final List<String> _presetResearch = [
    "🔬 研究：每周2-3次力量训练可增加肌肉质量并提高骨密度。",
    "🔬 蛋白质摄入时机：训练后30分钟内补充20-25g蛋白质最能促进肌肉合成。",
    "🔬 HIIT 训练能显著提高心肺功能和胰岛素敏感性。",
    "🔬 睡眠不足会降低肌肉恢复速度并增加受伤风险。",
    "🔬 渐进超负荷是肌肉增长的核心原则。",
    "🔬 离心收缩比向心收缩更能引发肌肉肥大。",
    "🔬 每天步行8000步可降低全因死亡率20%。",
    "🔬 抗阻训练可改善老年人认知功能。",
    "🔬 运动后冰浴可能减弱肌肉蛋白合成。",
    "🔬 咖啡因能提高耐力运动表现约5-10%。",
    "🔬 补充肌酸可增加肌肉力量和爆发力。",
    "🔬 运动前动态拉伸比静态拉伸更能提升表现。",
    "🔬 高强度力量训练后需要48小时恢复。",
    "🔬 饮食中蛋白质应均匀分配于每餐。",
    "🔬 维生素D缺乏会降低肌肉功能。",
    "🔬 每日摄入1.6-2.2g/kg蛋白质对增肌最佳。",
    "🔬 复合动作（深蹲、硬拉）比孤立动作更高效。",
    "🔬 女性进行力量训练不会变得粗壮，反而更紧致。",
    "🔬 训练多样化可避免平台期。",
    "🔬 冥想结合运动能减轻压力。",
    "🔬 研究：大重量低次数（4-6次）主要增强力量。",
    "🔬 中高次数（8-12次）最利于肌肉肥大。",
    "🔬 高次数（15+次）主要提升耐力。",
    "🔬 训练容量（组数×次数×重量）是增肌关键。",
    "🔬 组间休息2-3分钟更适合力量训练。",
    "🔬 组间休息45-90秒更适合增肌训练。",
    "🔬 运动前摄入碳水化合物可提高耐力。",
    "🔬 训练后补充蛋白质促进肌肉修复。",
    "🔬 水合状态影响运动表现达20%。",
    "🔬 核心稳定性训练可预防下背痛。",
    "🔬 平衡训练可减少老年人跌倒风险。",
    "🔬 柔韧性训练可提高关节活动度。",
    "🔬 爆发力训练（跳箱、药球）提高运动表现。",
    "🔬 速度训练可提高神经系统效率。",
    "🔬 敏捷性训练可减少运动损伤。",
    "🔬 长期有氧运动可增加海马体体积。",
    "🔬 运动可缓解抑郁症状，效果类似药物。",
    "🔬 运动后内啡肽释放产生愉悦感。",
    "🔬 睾酮在力量训练后短暂升高。",
    "🔬 生长激素在睡眠和训练后分泌。",
    "🔬 皮质醇过高会分解肌肉。",
    "🔬 胰岛素敏感性随运动提高。",
    "🔬 运动可降低静息心率。",
    "🔬 最大摄氧量是心肺耐力指标。",
    "🔬 无氧阈值越高耐力越强。",
    "🔬 肌肉纤维分为I型（慢肌）和II型（快肌）。",
    "🔬 快肌纤维更容易肥大。",
    "🔬 慢肌纤维更耐疲劳。",
    "🔬 基因决定肌肉纤维比例。",
    "🔬 年龄增长导致肌肉流失（肌少症）。",
    "🔬 力量训练是预防肌少症最有效方法。"
  ];

  static final List<String> _presetEncouragements = [
    "💪 每一次力竭都是成长的信号！",
    "💪 坚持就是胜利，肌肉在休息时生长。",
    "💪 你流的每一滴汗，都在雕刻更好的自己。",
    "💪 别放弃，今天的痛苦是明天的力量。",
    "💪 健身是最好的抗衰老药。",
    "💪 运动改变大脑，让你更快乐。",
    "💪 没有借口，只有更好的自己。",
    "💪 身体是灵魂的殿堂，保持洁净。",
    "💪 进步来自舒适区之外。",
    "💪 每天进步1%，一年强大37倍。",
    "💪 运动是你能为自己做的最好的投资。",
    "💪 累吗？说明你在走上坡路。",
    "💪 健身不是为了比过别人，而是为了超越昨天的自己。",
    "💪 汗水不会欺骗你。",
    "💪 肌肉是用痛苦交换的礼物。",
    "💪 成功不是将来才有的，而是从决定去做的那一刻起，持续累积而成。",
    "💪 健身是唯一付出就一定会有回报的事情。",
    "💪 不要让昨天的疲惫，阻止今天的你。",
    "💪 强壮的身体，是意志力的证明。",
    "💪 训练时你对抗的是重力，生活中你对抗的是惰性。",
    "💪 每次力竭，都是肌肉在呐喊生长。",
    "💪 健身让你成为更好的自己。",
    "💪 只有汗水不会骗你。",
    "💪 坚持，就是胜利。",
    "💪 别让懒惰占据你的生活。",
    "💪 健身是一种生活态度。",
    "💪 每天进步一点点。",
    "💪 相信自己，你可以。",
    "💪 没有痛苦，就没有收获。",
    "💪 健身让你更自信。"
  ];

  static final List<String> _presetTips = [
    "💡 训练前动态热身，训练后静态拉伸。",
    "💡 每组最后一两次要竭尽全力。",
    "💡 保持水分，每天至少喝2-3升水。",
    "💡 睡眠7-9小时对恢复至关重要。",
    "💡 使用大重量低次数（4-6次）增力，中重量中次数（8-12次）增肌。",
    "💡 训练计划每6-8周调整一次。",
    "💡 动作质量比重量更重要。",
    "💡 训练后补充碳水化合物和蛋白质。",
    "💡 记录训练日志以追踪进步。",
    "💡 不要忽视核心训练。",
    "💡 深蹲时膝盖不要内扣。",
    "💡 硬拉保持背部挺直。",
    "💡 卧推时肩胛骨收紧。",
    "💡 引体向上避免摆动借力。",
    "💡 有氧和力量训练分开进行效果更佳。",
    "💡 训练前摄入咖啡因可提高专注力。",
    "💡 训练后冷热交替淋浴促进恢复。",
    "💡 使用泡沫轴放松肌肉。",
    "💡 每周至少休息1-2天。",
    "💡 训练强度比训练量更重要。",
    "💡 多样化训练避免平台期。",
    "💡 倾听身体信号，避免过度训练。",
    "💡 大重量训练时使用腰带保护腰部。",
    "💡 握力带可辅助大重量拉类动作。",
    "💡 训练前2小时进食，避免空腹。",
    "💡 训练中补充电解质。",
    "💡 训练后补充快碳（如香蕉、白面包）。",
    "💡 使用训练App记录进度。",
    "💡 寻找训练伙伴互相激励。",
    "💡 设定短期和长期目标。"
  ];

  static final List<String> _presetFacts = [
    "📚 蛋白质摄入建议每公斤体重1.6-2.2克。",
    "📚 睡眠不足会抑制肌肉恢复。",
    "📚 一磅肌肉每天消耗约6-10卡路里。",
    "📚 运动后过量氧耗（EPOC）可持续数小时。",
    "📚 人体有超过600块肌肉。",
    "📚 最大心率约为220减去年龄。",
    "📚 高强度间歇训练（HIIT）后燃效应更强。",
    "📚 水占肌肉重量的75%左右。",
    "📚 力量训练可提高基础代谢率。",
    "📚 久坐每小时起身活动2分钟可降低血糖。",
    "📚 深蹲可以锻炼全身200多块肌肉。",
    "📚 拉伸不能预防所有运动损伤，但能提高柔韧性。",
    "📚 肌肉酸痛并不代表训练有效。",
    "📚 基因影响肌肉形态和增长潜力。",
    "📚 女性睾酮水平仅为男性1/10，不会轻易练出大块肌肉。",
    "📚 一公斤脂肪约含7700卡路里。",
    "📚 肌肉密度大于脂肪。",
    "📚 体重指数(BMI)不区分肌肉和脂肪。",
    "📚 体脂率是更准确的健康指标。",
    "📚 内脏脂肪危害最大。",
    "📚 褐色脂肪帮助燃烧热量。",
    "📚 寒冷环境可激活褐色脂肪。",
    "📚 禁食16小时以上开始消耗脂肪。",
    "📚 生酮饮食初期体重下降主要是水分。",
    "📚 碳水化合物不是肥胖元凶，总热量才是。",
    "📚 膳食纤维有助于控制体重。",
    "📚 蛋白质热效应最高（20-30%）。",
    "📚 碳水化合物热效应5-10%。",
    "📚 脂肪热效应0-3%。",
    "📚 食物热效应占总消耗10%。"
  ];

  static final List<String> _presetMyths = [
    "🧠 局部减脂不存在。",
    "🧠 流汗多不等于减脂多。",
    "🧠 肌肉不会变成脂肪，两者不同组织。",
    "🧠 举重不会让你变矮。",
    "🧠 女性举重不会变壮硕。",
    "🧠 训练后不需要立即喝蛋白粉。",
    "🧠 有氧运动不会燃烧肌肉（只要摄入足够蛋白质）。",
    "🧠 碳水化合物不会让你变胖，过量热量才会。",
    "🧠 力量训练不会降低柔韧性。",
    "🧠 老年人也可以增肌。",
    "🧠 健身补剂不是必须的。",
    "🧠 肌肉酸痛不代表肌肉增长。",
    "🧠 空腹有氧并不更减脂。",
    "🧠 拉伸不会防止肌肉拉伤。",
    "🧠 健身不需要每天练。",
    "🧠 训练后肌肉酸痛是乳酸堆积？不，是微损伤。",
    "🧠 吃脂肪不会让你长脂肪。",
    "🧠 基础代谢低不是肥胖主因。",
    "🧠 排毒产品是骗局。",
    "🧠 燃脂心率区不是必须的。",
    "🧠 健身不会让你变笨重。",
    "🧠 重量训练不会让女性变成金刚芭比。",
    "🧠 健身可以改善皮肤。",
    "🧠 健身不会导致脱发（除非基因）。",
    "🧠 健身不会让你长不高（青少年）。",
    "🧠 健身不会影响生育。",
    "🧠 健身不会导致肾损伤（除非滥用药物）。"
  ];

  static final List<String> _presetProtocols = [
    "🏋️ 渐进超负荷原则：逐步增加重量或次数。",
    "🏋️ 复合动作是基础：深蹲、硬拉、卧推。",
    "🏋️ 分化训练：推拉腿、上下肢分化。",
    "🏋️ 周期性训练：力量、增肌、耐力周期轮换。",
    "🏋️ 热身组：先用轻重量激活神经。",
    "🏋️ 超级组：拮抗肌群交替训练节省时间。",
    "🏋️ 递减组：力竭后减重继续，增加代谢压力。",
    "🏋️ 休息暂停：每组最后力竭后休息15秒再完成几次。",
    "🏋️ 离心强化：慢放阶段增加时间。",
    "🏋️ 血流限制训练：用轻重量达到类似大重量效果。",
    "🏋️ 塔巴塔训练：20秒冲刺10秒休息，共8轮。",
    "🏋️ 法特莱克跑：变速跑提高耐力。",
    "🏋️ 5x5训练法：5组5次，专注力量。",
    "🏋️ 10x10德国壮汉训练：高容量增肌。",
    "🏋️ 三组8-12次：经典增肌范围。",
    "🏋️ 每周3次全身训练适合初学者。",
    "🏋️ 每周4次上下肢分化适合中级。",
    "🏋️ 每周5次推拉腿分化适合高级。",
    "🏋️ 训练前动态拉伸：弓步转体、高抬腿。",
    "🏋️ 训练后静态拉伸：每个部位保持20秒。",
    "🏋️ 主动恢复日：低强度有氧或瑜伽。",
    "🏋️ 减载周：每6-8周降低强度50%。",
    "🏋️ 优先训练弱项：先做弱势部位。",
    "🏋️ 训练顺序：复合动作→孤立动作。",
    "🏋️ 大重量组前增加神经激活组。",
    "🏋️ 使用弹力带辅助引体向上。",
    "🏋️ 使用TRX训练核心稳定性。",
    "🏋️ 壶铃摇摆锻炼后链。",
    "🏋️ 保加利亚分腿蹲单侧训练。",
    "🏋️ 罗马尼亚硬拉针对腘绳肌。"
  ];

  static List<String> _getPresetResearch() => _presetResearch;
  static List<String> _getPresetEncouragements() => _presetEncouragements;
  static List<String> _getPresetTips() => _presetTips;
  static List<String> _getPresetFacts() => _presetFacts;
  static List<String> _getPresetMyths() => _presetMyths;
  static List<String> _getPresetProtocols() => _presetProtocols;
}