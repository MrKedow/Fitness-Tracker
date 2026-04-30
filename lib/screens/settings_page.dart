import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../main.dart';
import '../services/knowledge_update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _presetImages = [];
  String _currentImagePath = 'assets/吉祥物奔奔猫.gif';

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // 修改：加载形象时过滤已删除的预设
  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    _currentImagePath = prefs.getString('coach_image') ?? 'assets/吉祥物奔奔猫.gif';
    final savedCustom = prefs.getStringList('coach_custom_images') ?? [];
    final deletedPresets = prefs.getStringList('coach_deleted_presets') ?? [];

    const allPresets = [
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

    final visiblePresets = allPresets.where((path) {
      final fileName = path.split('/').last;
      return !deletedPresets.contains(fileName);
    }).toList();

    _presetImages = [...visiblePresets, ...savedCustom];
    if (mounted) setState(() {});
  }

  Future<void> _saveCustomImages() async {
    final prefs = await SharedPreferences.getInstance();
    const defaultCount = 12;
    if (_presetImages.length > defaultCount) {
      final custom = _presetImages.sublist(defaultCount);
      await prefs.setStringList('coach_custom_images', custom);
    } else {
      await prefs.remove('coach_custom_images');
    }
  }

  Future<void> _saveDeletedPresets(List<String> deletedFileNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('coach_deleted_presets', deletedFileNames);
  }

  Future<void> _resetDefaultImages() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置默认形象'),
        content: const Text('恢复所有被删除的默认形象，是否继续？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('重置')),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('coach_deleted_presets');
    await _loadImages();

    // 如果当前选中的形象是被删除的预设之一，则切换到第一个可用形象
    if (!_presetImages.contains(_currentImagePath) &&
        _currentImagePath.startsWith('assets/')) {
      final newImage =
          _presetImages.isNotEmpty ? _presetImages.first : 'assets/吉祥物奔奔猫.gif';
      setState(() {
        _currentImagePath = newImage;
      });
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setString('coach_image', newImage);
      _showToast('当前形象已被重置，已切换到默认形象');
    } else {
      _showToast('已恢复所有默认形象');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 完整的形象选择菜单（带删除和重置功能）
  void _showChangeImageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            List<String> currentImages = List.from(_presetImages);

            Future<List<String>> getDeletedPresets() async {
              final prefs = await SharedPreferences.getInstance();
              return prefs.getStringList('coach_deleted_presets') ?? [];
            }

            Future<void> removeImage(String imagePath) async {
              final isPreset = imagePath.startsWith('assets/');
              final fileName = imagePath.split('/').last;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('删除形象'),
                  content: Text(
                      '确定要删除 ${fileName.replaceAll('.gif', '').replaceAll('.png', '')} 吗？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              if (isPreset) {
                final prefs = await SharedPreferences.getInstance();
                final deletedPresets = await getDeletedPresets();
                if (!deletedPresets.contains(fileName)) {
                  deletedPresets.add(fileName);
                  await prefs.setStringList(
                      'coach_deleted_presets', deletedPresets);
                }
                setState(() {
                  _presetImages.remove(imagePath);
                });
                setStateBottomSheet(() {
                  currentImages.remove(imagePath);
                });
              } else {
                final file = File(imagePath);
                if (await file.exists()) await file.delete();
                setState(() {
                  _presetImages.remove(imagePath);
                });
                setStateBottomSheet(() {
                  currentImages.remove(imagePath);
                });
                await _saveCustomImages();
              }

              if (_currentImagePath == imagePath) {
                final newImage = currentImages.isNotEmpty
                    ? currentImages.first
                    : 'assets/吉祥物奔奔猫.gif';
                setState(() {
                  _currentImagePath = newImage;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('coach_image', newImage);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('当前形象已被删除，已切换到默认形象')),
                  );
                }
              } else {
                _showToast('已删除形象');
              }
            }

            return SafeArea(
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
                    const Text('选择陪练形象',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...currentImages.map((img) {
                      final fileName = img.split('/').last;
                      final displayName = fileName
                          .replaceAll('.gif', '')
                          .replaceAll('.png', '');
                      return ListTile(
                        leading: img.startsWith('assets/')
                            ? Image.asset(img,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image))
                            : Image.file(File(img),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image)),
                        title: Text(displayName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentImagePath == img)
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => removeImage(img),
                              tooltip: '删除形象',
                            ),
                          ],
                        ),
                        onTap: () async {
                          setState(() {
                            _currentImagePath = img;
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('coach_image', img);
                          Navigator.pop(context);
                          _showToast('形象已更换');
                        },
                      );
                    }),
                    ListTile(
                      leading: const Icon(Icons.add_photo_alternate,
                          color: Colors.blue),
                      title: const Text('添加自定义图片'),
                      subtitle: const Text('从相册选择 GIF 或 PNG',
                          style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final appDir =
                              await getApplicationDocumentsDirectory();
                          final fileName =
                              'coach_${DateTime.now().millisecondsSinceEpoch}.png';
                          final savedPath = '${appDir.path}/$fileName';
                          await File(pickedFile.path).copy(savedPath);
                          setState(() {
                            _currentImagePath = savedPath;
                            _presetImages.add(savedPath);
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('coach_image', savedPath);
                          await _saveCustomImages();
                          setStateBottomSheet(() {
                            currentImages.add(savedPath);
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            _showToast('自定义形象已添加');
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.green),
                      title: const Text('重置默认形象'),
                      subtitle: const Text('恢复所有被删除的预设形象',
                          style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        await _resetDefaultImages();
                        setStateBottomSheet(() {
                          currentImages = List.from(_presetImages);
                        });
                        _showToast('已重置默认形象');
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('显示可拖拽小猫'),
            subtitle: const Text('在主界面显示一只可拖拽的吉祥物'),
            value: settingsProvider.showDraggableCat,
            onChanged: (value) => settingsProvider.setShowDraggableCat(value),
          ),
          ListTile(
            title: const Text('AI陪练形象'),
            subtitle: const Text('点击更换形象（支持自定义图片）'),
            onTap: () => _showChangeImageMenu(context),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('自动更新AI知识库'),
            subtitle: const Text('开启后，每次启动应用会在后台更新健身语料'),
            value: settingsProvider.autoUpdateKnowledge,
            onChanged: (value) =>
                settingsProvider.setAutoUpdateKnowledge(value),
          ),
          ListTile(
            title: const Text('查看语料库状态'),
            subtitle: const Text('点击查看各分类条目数量'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final stats = await KnowledgeUpdateService.getStats();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      bool isUpdating = false;
                      Map<String, int> currentStats = Map.from(stats);
                      return AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.library_books),
                            SizedBox(width: 8),
                            Text('语料库状态')
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...currentStats.entries.map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${e.key}:'),
                                      Text('${e.value} 条',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('手动更新',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                                if (isUpdating)
                                  const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                else
                                  TextButton.icon(
                                    onPressed: () async {
                                      if (!mounted) return;
                                      setState(() => isUpdating = true);
                                      final success =
                                          await KnowledgeUpdateService
                                              .runUpdate();
                                      if (!mounted) return;
                                      if (success) {
                                        final newStats =
                                            await KnowledgeUpdateService
                                                .getStats();
                                        if (!mounted) return;
                                        setState(() {
                                          currentStats = Map.from(newStats);
                                          isUpdating = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('手动更新成功！')),
                                        );
                                      } else {
                                        setState(() => isUpdating = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('更新失败，请稍后重试'),
                                              backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('更新'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('关闭')),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('关于'),
            subtitle: const Text('版本信息及联系方式'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('关于')
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('健身数据管理系统',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('版本: Android_v1.1',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      const Text('本项目是一个开源的健身数据管理工具，支持AI分析和多端同步。'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(
                            'https://github.com/MrKedow/Fitness-Tracker')),
                        child: const Text('我的Github：MrKedow',
                            style: TextStyle(color: Colors.blue)),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () =>
                            launchUrl(Uri.parse('mailto:Ethocas@outlook.com')),
                        child: const Text('我的邮箱：Ethocas@outlook.com',
                            style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
