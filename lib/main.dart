import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fitness_tracker/widgets/roaming_cat.dart';
import 'package:fitness_tracker/widgets/coach_character.dart';
import 'package:webview_windows/webview_windows.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 WebView Windows 平台
  // if (Platform.isWindows) {
    // await WebviewController.initialize();
  // }
  final prefs = await SharedPreferences.getInstance();
  final savedThemeIndex = prefs.getInt('selected_theme') ?? 0;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(savedThemeIndex)),
        Provider(create: (_) => ExcelCSVService()),
        ChangeNotifierProvider(create: (_) => NutstoreService()),
      ],
      child: const FitnessApp(),
    ),
  );
}

// ==================== 主题管理 ====================
class ThemeProvider extends ChangeNotifier {
  int _selectedThemeIndex;

  ThemeProvider(this._selectedThemeIndex);

  int get selectedThemeIndex => _selectedThemeIndex;

  void setTheme(int index) async {
    _selectedThemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme', index);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _themes[_selectedThemeIndex];
  }

  static final List<ThemeData> _themes = [
    // 0: 远山青（深青色渐变风格）
    ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3AB8C7),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3AB8C7),
        secondary: Color(0xFF2E8B9E),
        surface: Color(0xFF1A2A3A),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A2A3A),
      cardColor: const Color(0xFF2A3A4A),
      dialogBackgroundColor: const Color(0xFF2A3A4A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A3A4A),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3AB8C7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A4A5A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
    
    // 1: 萤石黑（极致纯黑）
    ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF007AFF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF5856D6),
        surface: Color(0xFF000000),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardColor: const Color(0xFF1C1C1E),
      dialogBackgroundColor: const Color(0xFF1C1C1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Color(0xFF007AFF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
    
    // 2: 珠玉白（明亮干净）
    ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4A6FA5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A6FA5),
        secondary: Color(0xFF6B8FC7),
        surface: Color(0xFFF8F9FA),
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Color(0xFF4A6FA5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A6FA5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
    ),
    
    // 3: 活力橙（热情明亮）
    ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFFF9500),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF9500),
        secondary: Color(0xFFFF6B00),
        surface: Color(0xFF1A1A1A),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF2A2A2A),
      dialogBackgroundColor: const Color(0xFF2A2A2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A2A2A),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Color(0xFFFF9500)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
    
    // 4: 全透明（毛玻璃效果）
    ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white70,
        surface: Colors.transparent,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: Colors.black.withOpacity(0.6),
      dialogBackgroundColor: Colors.black.withOpacity(0.85),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white60),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
  ];
}

// ==================== 数据模型 ====================
class WorkoutRecord {
  final String id;
  DateTime date;
  int sessionNumber;
  List<WorkoutProject> projects;
  final DateTime timestamp;

  WorkoutRecord({
    required this.id,
    required this.date,
    required this.sessionNumber,
    required this.projects,
    required this.timestamp,
  });

  double get totalWork {
    return projects.fold(0.0, (sum, project) => sum + project.calculateWork());
  }
}

class WorkoutProject {
  String name;
  String part;
  double weight;
  int sets;
  int repsPerSet;
  String feeling;
  String supplement;

  WorkoutProject({
    required this.name,
    required this.part,
    required this.weight,
    required this.sets,
    required this.repsPerSet,
    required this.feeling,
    required this.supplement,
  });

  factory WorkoutProject.empty() {
    return WorkoutProject(
      name: '',
      part: '胸',
      weight: 0,
      sets: 0,
      repsPerSet: 0,
      feeling: '',
      supplement: '',
    );
  }

  WorkoutProject copy() {
    return WorkoutProject(
      name: name,
      part: part,
      weight: weight,
      sets: sets,
      repsPerSet: repsPerSet,
      feeling: feeling,
      supplement: supplement,
    );
  }

  double calculateWork() {
    final travelDistances = {
      '肩': 0.6,
      '背': 0.6,
      '腿': 0.7,
      '胸': 0.6,
      '腹': 0,
    };

    if (part == '腹') {
      return (sets * repsPerSet * 100).toDouble();
    } else {
      final distance = travelDistances[part] ?? 0;
      return (weight * 9.8 * distance * sets * repsPerSet);
    }
  }
}

// ==================== 状态管理 ====================
class WorkoutProvider extends ChangeNotifier {
  List<WorkoutRecord> _records = [];
  String? _lastExportPath;

  List<WorkoutRecord> get records => _records;
  String? get lastExportPath => _lastExportPath;

  void setLastExportPath(String path) {
    _lastExportPath = path;
    _saveLastExportPath(path);
    notifyListeners();
  }

  Future<void> _saveLastExportPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_export_path', path);
  }

  Future<void> loadLastExportPath() async {
    final prefs = await SharedPreferences.getInstance();
    _lastExportPath = prefs.getString('last_export_path');
    notifyListeners();
  }

  void addRecord(WorkoutRecord record) {
    _records.add(record);
    _saveRecords();
    notifyListeners();
  }

  void updateRecord(String id, WorkoutRecord updatedRecord) {
    final index = _records.indexWhere((record) => record.id == id);
    if (index != -1) {
      _records[index] = updatedRecord;
      _saveRecords();
      notifyListeners();
    }
  }

  void deleteRecord(String id) {
    _records.removeWhere((record) => record.id == id);
    _saveRecords();
    notifyListeners();
  }

  void loadRecords(List<WorkoutRecord> newRecords) {
    _records = newRecords;
    notifyListeners();
  }

  void clearRecords() {
    _records.clear();
    _saveRecords();
    notifyListeners();
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = _records.map((record) {
      return {
        'id': record.id,
        'date': record.date.toIso8601String(),
        'sessionNumber': record.sessionNumber,
        'projects': record.projects.map((project) {
          return {
            'name': project.name,
            'part': project.part,
            'weight': project.weight,
            'sets': project.sets,
            'repsPerSet': project.repsPerSet,
            'feeling': project.feeling,
            'supplement': project.supplement,
          };
        }).toList(),
        'timestamp': record.timestamp.toIso8601String(),
      };
    }).toList();

    await prefs.setString('workout_records', json.encode(recordsJson));
  }

  Future<void> loadSavedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString('workout_records');

    if (recordsJson != null) {
      try {
        final List<dynamic> data = json.decode(recordsJson);
        _records = data.map((item) {
          return WorkoutRecord(
            id: item['id'],
            date: DateTime.parse(item['date']),
            sessionNumber: item['sessionNumber'],
            projects: (item['projects'] as List).map((project) {
              return WorkoutProject(
                name: project['name'],
                part: project['part'],
                weight: project['weight']?.toDouble() ?? 0,
                sets: project['sets']?.toInt() ?? 0,
                repsPerSet: project['repsPerSet']?.toInt() ?? 0,
                feeling: project['feeling'] ?? '',
                supplement: project['supplement'] ?? '',
              );
            }).toList(),
            timestamp: DateTime.parse(item['timestamp']),
          );
        }).toList();
      } catch (e) {
        print('加载保存的记录失败: $e');
      }
    }

    notifyListeners();
  }
}

// ==================== Excel/CSV 服务 ====================
class ExcelCSVService {
  static const String _defaultFilename = '健身数据实时表.csv';

  Future<String?> exportToCSV(List<WorkoutRecord> records) async {
    try {
      final csvContent = _createCSVContent(records);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$_defaultFilename';
      final file = File(filePath);
      await file.writeAsString(csvContent, encoding: utf8);
      print('CSV文件已保存到: $filePath');
      return filePath;
    } catch (e) {
      print('导出CSV失败: $e');
      rethrow;
    }
  }

  String _createCSVContent(List<WorkoutRecord> records) {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('日期,第几次健身,项目名称,锻炼部位,重量(kg),组数,每组数量,做功(J),感受,补剂,记录时间');

    if (records.isEmpty) {
      return buffer.toString();
    }

    final sortedRecords = List<WorkoutRecord>.from(records)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.sessionNumber.compareTo(b.sessionNumber);
      });

    String? lastDateStr;
    int? lastSessionNumber;

    for (final record in sortedRecords) {
      final dateStr = DateFormat('yyyy-MM-dd').format(record.date);

      for (int i = 0; i < record.projects.length; i++) {
        final project = record.projects[i];
        if (project.name.isNotEmpty) {
          if (dateStr == lastDateStr && record.sessionNumber == lastSessionNumber && i > 0) {
            buffer.write(',');
          } else {
            buffer.write('$dateStr,');
            lastDateStr = dateStr;
            lastSessionNumber = record.sessionNumber;
          }

          buffer.write('${record.sessionNumber},');
          buffer.write('"${_escapeCSV(project.name)}",');
          buffer.write('${project.part},');
          buffer.write('${project.weight},');
          buffer.write('${project.sets},');
          buffer.write('${project.repsPerSet},');
          buffer.write('${project.calculateWork()},');
          buffer.write('"${_escapeCSV(project.feeling)}",');
          buffer.write('"${_escapeCSV(project.supplement)}",');
          buffer.write('"${record.timestamp.toIso8601String()}"');
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  String _escapeCSV(String input) {
    if (input.contains('"') || input.contains(',') || input.contains('\n')) {
      return input.replaceAll('"', '""');
    }
    return input;
  }

  Future<List<WorkoutRecord>> importFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final content = await file.readAsString(encoding: utf8);
      final lines = LineSplitter.split(content).toList();

      if (lines.isEmpty) {
        return [];
      }

      final records = <WorkoutRecord>[];
      final recordMap = <String, WorkoutRecord>{};

      int startIndex = 0;
      if (lines[0].startsWith('\uFEFF')) {
        lines[0] = lines[0].substring(1);
      }

      String? currentDateStr;
      int? currentSessionNum;

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        final cells = _parseCSVLine(line);
        if (cells.length < 3) continue;

        try {
          String dateStr = cells[0];
          if (dateStr.isEmpty && currentDateStr != null) {
            dateStr = currentDateStr;
          } else if (dateStr.isNotEmpty) {
            currentDateStr = dateStr;
          }

          int sessionNum;
          if (cells[1].isEmpty && currentSessionNum != null) {
            sessionNum = currentSessionNum;
          } else {
            sessionNum = int.tryParse(cells[1]) ?? 0;
            currentSessionNum = sessionNum;
          }

          final projectName = cells[2];

          if (dateStr.isEmpty || sessionNum == 0 || projectName.isEmpty) {
            continue;
          }

          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final recordKey = '${date.toIso8601String()}_$sessionNum';

          if (!recordMap.containsKey(recordKey)) {
            final record = WorkoutRecord(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              date: date,
              sessionNumber: sessionNum,
              projects: [],
              timestamp: cells.length > 10 ? DateTime.parse(cells[10]) : DateTime.now(),
            );
            recordMap[recordKey] = record;
            records.add(record);
          }

          final project = WorkoutProject(
            name: projectName,
            part: cells.length > 3 ? cells[3] : '胸',
            weight: cells.length > 4 ? double.tryParse(cells[4]) ?? 0 : 0,
            sets: cells.length > 5 ? int.tryParse(cells[5]) ?? 0 : 0,
            repsPerSet: cells.length > 6 ? int.tryParse(cells[6]) ?? 0 : 0,
            feeling: cells.length > 8 ? cells[8] : '',
            supplement: cells.length > 9 ? cells[9] : '',
          );

          recordMap[recordKey]!.projects.add(project);
        } catch (e) {
          print('解析CSV行失败: $e, 行内容: $line');
        }
      }

      return records;
    } catch (e) {
      print('导入CSV失败: $e');
      rethrow;
    }
  }

  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    final chars = line.split('');
    StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '"') {
        if (i + 1 < chars.length && chars[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }

    result.add(current.toString());
    return result;
  }
}

// ==================== 坚果云服务 ====================
class NutstoreService extends ChangeNotifier {
  static const String _baseUrl = 'https://dav.jianguoyun.com/dav/';
  static const String _cloudFolder = '健身数据管理系统';
  static const String _defaultFilename = '健身数据实时表.csv';

  String? _username;
  String? _password;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get username => _username;

  String _getAuthHeader() {
    if (_username == null || _password == null) {
      throw Exception('未设置用户名或密码');
    }
    final credentials = '$_username:$_password';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  Future<bool> connect({
    required String username,
    required String password,
    bool saveCredentials = true,
  }) async {
    try {
      _username = username;
      _password = password;

      final client = http.Client();
      final url = Uri.parse(_baseUrl);
      final request = http.Request('PROPFIND', url);
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Depth'] = '0';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode == 207) {
        _isConnected = true;
        await _ensureCloudFolder();
        if (saveCredentials) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('nutstore_username', username);
          await prefs.setString('nutstore_password', password);
        }
        notifyListeners();
        return true;
      } else {
        print('连接坚果云失败: 状态码 ${response.statusCode}');
        _isConnected = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('连接坚果云失败: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('nutstore_username');
      final password = prefs.getString('nutstore_password');

      if (username == null || password == null) {
        return false;
      }

      return await connect(
        username: username,
        password: password,
        saveCredentials: false,
      );
    } catch (e) {
      print('加载保存的配置失败: $e');
      return false;
    }
  }

  Future<void> _ensureCloudFolder() async {
    try {
      final folderUrl = Uri.parse('$_baseUrl${Uri.encodeComponent(_cloudFolder)}');
      final client = http.Client();
      final checkReq = http.Request('PROPFIND', Uri.parse('$folderUrl/'));
      checkReq.headers['Authorization'] = _getAuthHeader();
      checkReq.headers['Depth'] = '1';
      final checkResp = await client.send(checkReq);
      final checkResponse = await http.Response.fromStream(checkResp);
      client.close();

      if (checkResponse.statusCode == 207) {
        print('云文件夹已存在: $_cloudFolder');
        return;
      }

      final mkcolClient = http.Client();
      final mkcolReq = http.Request('MKCOL', folderUrl);
      mkcolReq.headers['Authorization'] = _getAuthHeader();
      final mkcolResp = await mkcolClient.send(mkcolReq);
      final mkcolResponse = await http.Response.fromStream(mkcolResp);
      mkcolClient.close();

      if (mkcolResponse.statusCode == 201) {
        print('云文件夹创建成功: $_cloudFolder');
      } else {
        print('云文件夹创建失败: 状态码${mkcolResponse.statusCode}');
      }
    } catch (e) {
      print('确保云文件夹存在失败: $e');
    }
  }

  Future<bool> uploadFile(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('本地文件不存在: $localFilePath');
        return false;
      }
      final remotePath = '$_baseUrl${Uri.encodeComponent(_cloudFolder)}/$_defaultFilename';
      print('正在上传文件到: $remotePath');
      final bytes = await file.readAsBytes();
      final url = Uri.parse(remotePath);

      final client = http.Client();
      final response = await client.put(
        url,
        headers: {
          'Authorization': _getAuthHeader(),
          'Content-Type': 'text/csv',
        },
        body: bytes,
      );
      client.close();

      if (response.statusCode == 201 || response.statusCode == 204) {
        print('上传成功');
        return true;
      } else {
        print('上传失败: 状态码${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('上传文件失败: $e');
      rethrow;
    }
  }

  Future<bool> downloadFile(String savePath) async {
    try {
      final remotePath = '$_baseUrl${Uri.encodeComponent(_cloudFolder)}/$_defaultFilename';
      print('正在从云盘下载文件: $remotePath');
      final url = Uri.parse(remotePath);

      final client = http.Client();
      final response = await client.get(
        url,
        headers: {
          'Authorization': _getAuthHeader(),
        },
      );
      client.close();

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        print('下载成功，已保存到: $savePath');
        return true;
      } else {
        print('下载失败: 状态码${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('下载文件失败: $e');
      rethrow;
    }
  }

  Future<bool> checkFileExists() async {
    try {
      final remotePath = '$_baseUrl${Uri.encodeComponent(_cloudFolder)}/$_defaultFilename';
      final url = Uri.parse(remotePath);

      final client = http.Client();
      final response = await client.head(
        url,
        headers: {
          'Authorization': _getAuthHeader(),
        },
      );
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      print('检查文件存在失败: $e');
      return false;
    }
  }

  void disconnect() {
    _isConnected = false;
    _username = null;
    _password = null;
    notifyListeners();
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nutstore_username');
    await prefs.remove('nutstore_password');
    disconnect();
    notifyListeners();
  }

  static String getHelpMessage() {
    return '''
坚果云 WebDAV 配置说明：

📌 重要提示：
1. 登录坚果云网页版 (https://www.jianguoyun.com)
2. 点击右上角账户名称 → 账户信息
3. 进入「安全选项」页面
4. 在「第三方应用管理」中点击「添加应用」
5. 输入应用名称（如：健身管理系统）
6. 生成并复制「应用密码」

🔧 连接配置：
服务器地址：https://dav.jianguoyun.com/dav
用户名：您的坚果云注册邮箱
密码：生成的应用密码（不是登录密码）

⚠️ 注意：
• 请使用应用密码，不要使用登录密码
• 确保坚果云账户有足够存储空间
• 如遇连接问题，请检查网络和防火墙设置
''';
  }
}

// ==================== 主应用 ====================
class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '健身数据管理系统 Fitness-Tracker_Win_v3.0',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const MainScreen(),
        );
      },
    );
  }
}

// ==================== 主界面 ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime selectedDate = DateTime.now();
  int sessionNumber = 1;
  final List<WorkoutProject> projects = [WorkoutProject.empty()];
  DateTime firstWorkoutDate = DateTime(2025, 6, 9, 18, 29);

  final TextEditingController dateController = TextEditingController();
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> weightControllers = [];
  final List<TextEditingController> setsControllers = [];
  final List<TextEditingController> repsControllers = [];
  final List<TextEditingController> feelingControllers = [];
  final List<TextEditingController> supplementControllers = [];
  final List<ValueNotifier<String>> partNotifiers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    _initializeControllers();
    _loadData();
    _loadFirstWorkoutDate();
  }

  void _loadData() async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    await provider.loadSavedRecords();
    await provider.loadLastExportPath();

    final nutstore = Provider.of<NutstoreService>(context, listen: false);
    await nutstore.loadSavedConfig();

    if (mounted) {
      setState(() {
        if (provider.records.isNotEmpty) {
          sessionNumber = provider.records.last.sessionNumber + 1;
        }
      });
    }
  }

  Future<void> _loadFirstWorkoutDate() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('first_workout_date');
    if (savedDate != null) {
      firstWorkoutDate = DateTime.parse(savedDate);
    } else {
      firstWorkoutDate = DateTime(2025, 6, 9, 18, 29);
    }
    setState(() {});
  }

  Future<void> _saveFirstWorkoutDate(DateTime newDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_workout_date', newDate.toIso8601String());
    firstWorkoutDate = newDate;
    setState(() {});
  }

  Future<void> _pickFirstWorkoutDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: firstWorkoutDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(firstWorkoutDate),
    );
    if (pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    await _saveFirstWorkoutDate(newDateTime);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('起始日期已更新，坚持天数已重新计算')),
    );
  }

  void _initializeControllers() {
    for (var project in projects) {
      nameControllers.add(TextEditingController(text: project.name));
      weightControllers.add(TextEditingController(text: project.weight.toString()));
      setsControllers.add(TextEditingController(text: project.sets.toString()));
      repsControllers.add(TextEditingController(text: project.repsPerSet.toString()));
      feelingControllers.add(TextEditingController(text: project.feeling));
      supplementControllers.add(TextEditingController(text: project.supplement));
      partNotifiers.add(ValueNotifier<String>(project.part));
    }
  }

  void _addProject() {
    setState(() {
      projects.add(WorkoutProject.empty());
      nameControllers.add(TextEditingController());
      weightControllers.add(TextEditingController());
      setsControllers.add(TextEditingController());
      repsControllers.add(TextEditingController());
      feelingControllers.add(TextEditingController());
      supplementControllers.add(TextEditingController());
      partNotifiers.add(ValueNotifier<String>('胸'));
    });
  }

  void _removeProject() {
    if (projects.length > 1) {
      setState(() {
        projects.removeLast();
        nameControllers.removeLast();
        weightControllers.removeLast();
        setsControllers.removeLast();
        repsControllers.removeLast();
        feelingControllers.removeLast();
        supplementControllers.removeLast();
        partNotifiers.removeLast();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveWorkout(BuildContext context) {
    final List<WorkoutProject> validProjects = [];

    for (int i = 0; i < projects.length; i++) {
      if (nameControllers[i].text.trim().isNotEmpty) {
        validProjects.add(WorkoutProject(
          name: nameControllers[i].text,
          part: partNotifiers[i].value,
          weight: double.tryParse(weightControllers[i].text) ?? 0,
          sets: int.tryParse(setsControllers[i].text) ?? 0,
          repsPerSet: int.tryParse(repsControllers[i].text) ?? 0,
          feeling: feelingControllers[i].text,
          supplement: supplementControllers[i].text,
        ));
      }
    }

    if (validProjects.isEmpty) {
      _showToast('请至少填写一个完整的训练项目', isError: true);
      return;
    }

    final record = WorkoutRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: selectedDate,
      sessionNumber: sessionNumber,
      projects: validProjects,
      timestamp: DateTime.now(),
    );

    Provider.of<WorkoutProvider>(context, listen: false).addRecord(record);

    setState(() {
      sessionNumber++;
      selectedDate = DateTime.now();
      dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);

      projects.clear();
      nameControllers.clear();
      weightControllers.clear();
      setsControllers.clear();
      repsControllers.clear();
      feelingControllers.clear();
      supplementControllers.clear();
      partNotifiers.clear();

      projects.add(WorkoutProject.empty());
      _initializeControllers();
    });

    _showToast('训练记录保存成功！');
  }

  Future<void> _exportToCSV(BuildContext context) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final excelService = Provider.of<ExcelCSVService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await excelService.exportToCSV(provider.records);

      if (filePath != null) {
        provider.setLastExportPath(filePath);
        _showExportSuccessDialog(context, filePath, provider.records.isEmpty);
      } else {
        _showToast('导出失败', isError: true);
      }
    } catch (e) {
      _showToast('导出失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadToCloud(BuildContext context) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final nutstore = Provider.of<NutstoreService>(context, listen: false);
    final excelService = Provider.of<ExcelCSVService>(context, listen: false);

    if (!nutstore.isConnected) {
      _showCloudLoginDialog(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await excelService.exportToCSV(provider.records);

      if (filePath == null) {
        _showToast('导出数据失败', isError: true);
        return;
      }

      provider.setLastExportPath(filePath);
      await nutstore.uploadFile(filePath);
      _showToast('数据已成功上传到坚果云！');
    } catch (e) {
      _showToast('上传失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFromCloud(BuildContext context) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final nutstore = Provider.of<NutstoreService>(context, listen: false);
    final excelService = Provider.of<ExcelCSVService>(context, listen: false);

    if (!nutstore.isConnected) {
      _showCloudLoginDialog(context);
      return;
    }

    final fileExists = await nutstore.checkFileExists();
    if (!fileExists) {
      _showToast('云文件中不存在，请先上传', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String savePath;
      if (provider.lastExportPath == null) {
        final directory = await getApplicationDocumentsDirectory();
        savePath = '${directory.path}/健身数据实时表.csv';
        provider.setLastExportPath(savePath);
      } else {
        savePath = provider.lastExportPath!;
      }

      await nutstore.downloadFile(savePath);
      final records = await excelService.importFromCSV(savePath);
      if (records.isNotEmpty) {
        provider.loadRecords(records);
        _showDownloadSuccessDialog(context, savePath);
      } else {
        _showToast('下载成功但导入失败，文件可能为空或格式错误', isError: true);
      }
    } catch (e) {
      _showToast('下载失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCloudLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool rememberPassword = true;
          bool isConnecting = false;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue),
                SizedBox(width: 10),
                Text('连接坚果云服务'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('服务器地址：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('https://dav.jianguoyun.com/dav', style: TextStyle(color: Colors.blue)),
                  const SizedBox(height: 15),
                  const Text('账户邮箱：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      hintText: '您的坚果云邮箱',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text('应用密码：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '坚果云应用密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberPassword,
                        onChanged: (value) {
                          setState(() {
                            rememberPassword = value ?? true;
                          });
                        },
                      ),
                      const Text('记住密码'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('坚果云配置帮助'),
                          content: Text(NutstoreService.getHelpMessage()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('查看配置说明'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: isConnecting ? null : () async {
                  setState(() {
                    isConnecting = true;
                  });

                  final nutstore = Provider.of<NutstoreService>(context, listen: false);
                  final connected = await nutstore.connect(
                    username: usernameController.text,
                    password: passwordController.text,
                    saveCredentials: rememberPassword,
                  );

                  if (connected && mounted) {
                    Navigator.pop(context);
                    _showToast('坚果云连接成功！');
                  } else {
                    _showToast('连接失败，请检查配置', isError: true);
                  }

                  setState(() {
                    isConnecting = false;
                  });
                },
                child: isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('连接'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCloudMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'logout',
          child: Text('退出云服务'),
        ),
        const PopupMenuItem(
          value: 'switch',
          child: Text('切换云账号'),
        ),
      ],
    ).then((value) {
      if (value == 'logout') {
        _logoutCloud();
      } else if (value == 'switch') {
        _switchCloudAccount();
      }
    });
  }

  Future<void> _logoutCloud() async {
    final nutstore = Provider.of<NutstoreService>(context, listen: false);
    await nutstore.clearCredentials();
    _showToast('已退出云服务', isError: false);
  }

  Future<void> _switchCloudAccount() async {
    await _logoutCloud();
    _showCloudLoginDialog(context);
  }

  void _showExportSuccessDialog(BuildContext context, String filePath, bool isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isEmpty ? Icons.info_outline : Icons.check_circle,
                color: isEmpty ? Colors.orange : Colors.green),
            const SizedBox(width: 10),
            Text(isEmpty ? '导出空模板成功' : '导出成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEmpty ? '空模板已成功导出到：' : '数据已成功导出到：'),
            const SizedBox(height: 10),
            Text(
              filePath,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            Text(isEmpty
                ? '这是一个空模板，您可以填写数据后导入使用。'
                : '文件已记录，可点击"上云"按钮上传到坚果云。'),
            if (!isEmpty) const SizedBox(height: 10),
            if (!isEmpty)
              const Text(
                '注意：同一天的训练项目在Excel中可以手动合并单元格，日期只在第一行显示。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
          if (!isEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadToCloud(context);
              },
              child: const Text('立即上云'),
            ),
        ],
      ),
    );
  }

  void _showDownloadSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('下载成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('数据已从坚果云下载到：'),
            const SizedBox(height: 10),
            Text(
              filePath,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            const Text('云数据已成功替换本地数据。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          onExport: () => _exportToCSV(context),
          onUpload: () => _uploadToCloud(context),
          onDownload: () => _downloadFromCloud(context),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 允许弹窗占据更多高度
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeNames = ['远山青', '萤石黑', '珠玉白', '活力橙', '全透明'];
        final themeColors = [
          const Color(0xFF3AB8C7),
          const Color(0xFF007AFF),
          const Color(0xFF4A6FA5),
          const Color(0xFFFF9500),
          Colors.white,
        ];
        final themeDescriptions = [
          '青绿渐变 · 清新自然',
          '深邃纯黑 · 专注高效',
          '温润米白 · 舒适护眼',
          '活力橙色 · 热情奔放',
          '毛玻璃效果 · 极简透明',
        ];

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择主题',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '不同主题会改变整体配色方案',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: themeNames.length,
                  itemBuilder: (context, index) {
                    final isSelected = themeProvider.selectedThemeIndex == index;
                    return GestureDetector(
                      onTap: () {
                        themeProvider.setTheme(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: index == 0
                              ? const LinearGradient(
                                  colors: [Color(0xFF3AB8C7), Color(0xFF2E8B9E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: index != 0 ? themeColors[index] : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? (index == 2 ? Colors.blue : Colors.white)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: themeColors[index].withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  themeNames[index],
                                  style: TextStyle(
                                    color: index == 2 ? Colors.black87 : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: index == 2 ? Colors.blue : Colors.white,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              themeDescriptions[index],
                              style: TextStyle(
                                color: index == 2 
                                    ? Colors.black54 
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProjectCard(int index) {
    return ValueListenableBuilder<String>(
      valueListenable: partNotifiers[index],
      builder: (context, part, child) {
        final weight = double.tryParse(weightControllers[index].text) ?? 0;
        final sets = int.tryParse(setsControllers[index].text) ?? 0;
        final reps = int.tryParse(repsControllers[index].text) ?? 0;
        final work = WorkoutProject(
          name: '',
          part: part,
          weight: weight,
          sets: sets,
          repsPerSet: reps,
          feeling: '',
          supplement: '',
        ).calculateWork();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '项目 ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameControllers[index],
                      decoration: const InputDecoration(
                        labelText: '项目名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: part,
                      decoration: const InputDecoration(
                        labelText: '锻炼部位',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['胸', '背', '腿', '肩', '腹']
                          .map((part) => DropdownMenuItem(
                                value: part,
                                child: Text(part),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          partNotifiers[index].value = value;
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '重量 (kg)',
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: setsControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '组数',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: repsControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '每组数量',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    '做功:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${work.toStringAsFixed(0)} J',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feelingControllers[index],
                      decoration: const InputDecoration(
                        labelText: '感受',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: supplementControllers[index],
                      decoration: const InputDecoration(
                        labelText: '补剂',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(firstWorkoutDate);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.fitness_center),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '健身数据管理系统 Win_v3.0',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SimSun',
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 700,
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: RoamingCat(
                  maxWidth: 700,
                  maxHeight: kToolbarHeight - 8,
                  githubUrl: 'https://github.com/MrKedow/Fitness-Tracker',
                  catSize: 45.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NutstoreService>(
            builder: (context, nutstore, child) {
              if (nutstore.isConnected) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        nutstore.username ?? '',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: '历史记录',
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => _showThemeSelector(context),
            tooltip: '切换主题',
          ),
          Consumer<NutstoreService>(
            builder: (context, nutstore, child) {
              return IconButton(
                icon: const Icon(Icons.cloud),
                onPressed: () {
                  if (nutstore.isConnected) {
                    _showCloudMenu(context);
                  } else {
                    _showCloudLoginDialog(context);
                  }
                },
                tooltip: '云服务',
              );
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('处理中...'),
                ],
              ),
            )
          : Consumer<WorkoutProvider>(
              builder: (context, provider, child) {
                final recentRecords = provider.records.take(5).toList();

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '健身坚持统计',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '每一次努力都值得记录',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: _pickFirstWorkoutDate,
                                    child: Text(
                                      '${duration.inDays} 天',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${duration.inHours % 24}小时 ${duration.inMinutes % 60}分钟',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '填写训练记录',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('📅 日期'),
                                                const SizedBox(height: 8),
                                                GestureDetector(
                                                  onTap: () => _selectDate(context),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).cardColor,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                                                        const SizedBox(width: 8),
                                                        Text(dateController.text),
                                                        const Spacer(),
                                                        const Icon(Icons.arrow_drop_down),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('#️⃣ 第几次训练'),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: TextEditingController(
                                                    text: sessionNumber.toString(),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    hintText: '输入次数',
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) {
                                                    final num = int.tryParse(value) ?? 1;
                                                    setState(() {
                                                      sessionNumber = num;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 30),

                                      const Text(
                                        '训练项目',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      Expanded(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: projects.length,
                                          itemBuilder: (context, index) {
                                            return _buildProjectCard(index);
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: _addProject,
                                            icon: const Icon(Icons.add),
                                            label: const Text('添加项目'),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: _removeProject,
                                            icon: const Icon(Icons.remove),
                                            label: const Text('删除项目'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).cardColor,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 30),

                                      ElevatedButton.icon(
                                        onPressed: () => _saveWorkout(context),
                                        icon: const Icon(Icons.save),
                                        label: const Text('保存记录'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF34C759),
                                          minimumSize: const Size(double.infinity, 56),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 24),

                            Expanded(
                              flex: 2,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '最近记录',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      Expanded(
                                        child: recentRecords.isEmpty
                                            ? const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.history, size: 60, color: Colors.grey),
                                                    SizedBox(height: 16),
                                                    Text('暂无记录'),
                                                    Text('开始您的第一次训练吧！', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: recentRecords.length,
                                                itemBuilder: (context, index) {
                                                  final record = recentRecords[index];
                                                  final dateStr = DateFormat('yyyy-MM-dd').format(record.date);
                                                  final projectNames = record.projects.map((p) => p.name).where((name) => name.isNotEmpty).join('、');
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).cardColor,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: Theme.of(context).primaryColor,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text('第${record.sessionNumber}次', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          projectNames.isNotEmpty ? projectNames : '无项目名称',
                                                          style: TextStyle(color: Colors.grey[400]),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            const Text('总做功'),
                                                            Text(
                                                              '${(record.totalWork / 1000).toStringAsFixed(1)}千焦',
                                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),

                                      const SizedBox(height: 20),

                                      OutlinedButton.icon(
                                        onPressed: () => _showHistory(context),
                                        icon: const Icon(Icons.list),
                                        label: const Text('查看全部记录'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 48),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ==================== 历史记录页面 ====================
class HistoryScreen extends StatefulWidget {
  final VoidCallback onExport;
  final VoidCallback onUpload;
  final VoidCallback onDownload;

  const HistoryScreen({
    super.key,
    required this.onExport,
    required this.onUpload,
    required this.onDownload,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedRecordId;
  WorkoutRecord? _recordToEdit;

  void _showContextMenu(BuildContext context, WorkoutRecord record) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('编辑'),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              _editRecord(record);
            });
          },
        ),
        PopupMenuItem(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              _deleteRecord(context, record);
            });
          },
        ),
      ],
    );
  }

  void _editRecord(WorkoutRecord record) {
    setState(() {
      _selectedRecordId = record.id;
      _recordToEdit = WorkoutRecord(
        id: record.id,
        date: record.date,
        sessionNumber: record.sessionNumber,
        projects: record.projects.map((p) => p.copy()).toList(),
        timestamp: record.timestamp,
      );
    });

    _showEditDialog();
  }

  void _showEditDialog() {
    if (_recordToEdit == null) return;

    final record = _recordToEdit!;
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(record.date));
    final sessionController = TextEditingController(text: record.sessionNumber.toString());

    final List<TextEditingController> nameControllers = [];
    final List<TextEditingController> weightControllers = [];
    final List<TextEditingController> setsControllers = [];
    final List<TextEditingController> repsControllers = [];
    final List<TextEditingController> feelingControllers = [];
    final List<TextEditingController> supplementControllers = [];
    final List<ValueNotifier<String>> partNotifiers = [];

    for (var project in record.projects) {
      nameControllers.add(TextEditingController(text: project.name));
      weightControllers.add(TextEditingController(text: project.weight.toString()));
      setsControllers.add(TextEditingController(text: project.sets.toString()));
      repsControllers.add(TextEditingController(text: project.repsPerSet.toString()));
      feelingControllers.add(TextEditingController(text: project.feeling));
      supplementControllers.add(TextEditingController(text: project.supplement));
      partNotifiers.add(ValueNotifier<String>(project.part));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void addProject() {
            setState(() {
              record.projects.add(WorkoutProject.empty());
              nameControllers.add(TextEditingController());
              weightControllers.add(TextEditingController());
              setsControllers.add(TextEditingController());
              repsControllers.add(TextEditingController());
              feelingControllers.add(TextEditingController());
              supplementControllers.add(TextEditingController());
              partNotifiers.add(ValueNotifier<String>('胸'));
            });
          }

          void removeProject() {
            if (record.projects.length > 1) {
              setState(() {
                record.projects.removeLast();
                nameControllers.removeLast();
                weightControllers.removeLast();
                setsControllers.removeLast();
                repsControllers.removeLast();
                feelingControllers.removeLast();
                supplementControllers.removeLast();
                partNotifiers.removeLast();
              });
            }
          }

          Future<void> selectDate() async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: record.date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );

            if (picked != null && picked != record.date) {
              setState(() {
                record.date = picked;
                dateController.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          }

          Widget buildProjectCard(int index) {
            return ValueListenableBuilder<String>(
              valueListenable: partNotifiers[index],
              builder: (context, part, child) {
                final weight = double.tryParse(weightControllers[index].text) ?? 0;
                final sets = int.tryParse(setsControllers[index].text) ?? 0;
                final reps = int.tryParse(repsControllers[index].text) ?? 0;
                final work = WorkoutProject(
                  name: '',
                  part: part,
                  weight: weight,
                  sets: sets,
                  repsPerSet: reps,
                  feeling: '',
                  supplement: '',
                ).calculateWork();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '项目 ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (record.projects.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (record.projects.length > 1) {
                                    record.projects.removeAt(index);
                                    nameControllers.removeAt(index);
                                    weightControllers.removeAt(index);
                                    setsControllers.removeAt(index);
                                    repsControllers.removeAt(index);
                                    feelingControllers.removeAt(index);
                                    supplementControllers.removeAt(index);
                                    partNotifiers.removeAt(index);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameControllers[index],
                              decoration: const InputDecoration(
                                labelText: '项目名称',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                record.projects[index].name = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: part,
                              decoration: const InputDecoration(
                                labelText: '锻炼部位',
                                border: OutlineInputBorder(),
                              ),
                              items: const ['胸', '背', '腿', '肩', '腹']
                                  .map((part) => DropdownMenuItem(
                                        value: part,
                                        child: Text(part),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  partNotifiers[index].value = value;
                                  record.projects[index].part = value;
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: weightControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '重量 (kg)',
                                border: OutlineInputBorder(),
                                suffixText: 'kg',
                              ),
                              onChanged: (value) {
                                record.projects[index].weight = double.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: setsControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '组数',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                record.projects[index].sets = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: repsControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '每组数量',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                record.projects[index].repsPerSet = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.bar_chart, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            '做功:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${work.toStringAsFixed(0)} J',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: feelingControllers[index],
                              decoration: const InputDecoration(
                                labelText: '感受',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                record.projects[index].feeling = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: supplementControllers[index],
                              decoration: const InputDecoration(
                                labelText: '补剂',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                record.projects[index].supplement = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 10),
                Text('编辑记录'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📅 日期'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Text(dateController.text),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('#️⃣ 第几次训练'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: sessionController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '输入次数',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final num = int.tryParse(value) ?? 1;
                                setState(() {
                                  record.sessionNumber = num;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ...List.generate(record.projects.length, (index) => buildProjectCard(index)),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: addProject,
                        icon: const Icon(Icons.add),
                        label: const Text('添加项目'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: removeProject,
                        icon: const Icon(Icons.remove),
                        label: const Text('删除项目'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedRecordId = null;
                    _recordToEdit = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final provider = Provider.of<WorkoutProvider>(context, listen: false);
                  provider.updateRecord(record.id, record);

                  setState(() {
                    _selectedRecordId = null;
                    _recordToEdit = null;
                  });

                  Navigator.pop(context);
                  _showToast('记录更新成功！');
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteRecord(BuildContext context, WorkoutRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('确认删除'),
          ],
        ),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<WorkoutProvider>(context, listen: false);
              provider.deleteRecord(record.id);
              Navigator.pop(context);
              _showToast('记录已删除');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('来时的路 - 完整历史记录'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  widget.onExport();
                  break;
                case 'upload':
                  widget.onUpload();
                  break;
                case 'download':
                  widget.onDownload();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('📤 导出CSV'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'upload',
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload, size: 20),
                    SizedBox(width: 8),
                    Text('☁️ 上云'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download, size: 20),
                    SizedBox(width: 8),
                    Text('📥 读云'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final records = provider.records;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                            const SizedBox(height: 20),
                            const Text('暂无历史记录'),
                            const SizedBox(height: 10),
                            const Text('开始您的第一次训练吧！'),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: widget.onExport,
                              icon: const Icon(Icons.download),
                              label: const Text('导出空模板'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('日期')),
                            DataColumn(label: Text('第几次')),
                            DataColumn(label: Text('项目数')),
                            DataColumn(label: Text('总做功')),
                            DataColumn(label: Text('详细内容')),
                            DataColumn(label: Text('操作')),
                          ],
                          rows: records.reversed.map((record) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(record.date);
                            final details = record.projects.map((p) {
                              if (p.name.isEmpty) return '';
                              return '${p.name}(${p.part}): ${p.weight}kg×${p.sets}×${p.repsPerSet}';
                            }).where((d) => d.isNotEmpty).join(' | ');
                            return DataRow(
                              onLongPress: () => _showContextMenu(context, record),
                              cells: [
                                DataCell(Text(dateStr)),
                                DataCell(Text('第${record.sessionNumber}次')),
                                DataCell(Text('${record.projects.length}')),
                                DataCell(Text('${(record.totalWork / 1000).toStringAsFixed(1)}千焦')),
                                DataCell(ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 400),
                                  child: Text(details.isNotEmpty ? details : '无详细信息'),
                                )),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editRecord(record),
                                      tooltip: '编辑',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteRecord(context, record),
                                      tooltip: '删除',
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: CoachCharacter(records: records),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}