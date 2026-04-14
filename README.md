# 💪 Fitness Tracker – 个人健身数据管理系统
一个专为个人健身记录设计的"本地优先、云端同步"的现代化桌面/移动应用。告别纸笔和复杂表格，用优雅的界面记录每一次训练，自动计算做功，并支持坚果云 WebDAV 一键同步。

#### 本项目CSDN链接：[https://blog.csdn.net/Ethocas/article/details/160124357](https://blog.csdn.net/Ethocas/article/details/160124357?fromshare=blogdetail&sharetype=blogdetail&sharerId=160124357&sharerefer=PC&sharesource=Ethocas&sharefrom=from_link)
## [🔈2026.04.15 点击进入：Fitness-Tracker_Win_v2.0 Release](https://github.com/MrKedow/Fitness-Tracker/releases/tag/Win_Newest_Stable)
---
## ✨ 核心功能
### 📝 智能表单填写
- **日期选择**：记录训练日期，自动计算“距第一次健身已过时间”（首次训练时间：**2025-06-09 18:29**）
- **动态项目列表**：点击 ➕ 添加多个训练项目，点击 ➖ 删除项目
- **详细字段**：
  - 项目名称（如：卧推、深蹲）
  - 锻炼部位（胸、背、腿、肩、腹）
  - 重量 (kg)
  - 组数 × 每组次数
  - 感受（文字描述）
  - 补剂（选填）
- **智能做功计算**：
  - 根据部位自动计算行程（肩/背/胸 60cm，腿 70cm）
  - 腹部采用科学估算（65kg成年人30°斜面仰卧起坐）
  - 实时显示本次训练的总做功（焦耳/千焦）
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/fcb5aa9a-eefa-42d7-8aa0-d2e43cdbae9b" />

### 📜 历史记录管理
- **“来时的路”页面**：展示所有已保存的训练记录
- **长按编辑/删除**：长按任意记录可修改数据或删除
- **本地持久化**：数据自动保存至本地数据库（SharedPreferences + JSON）
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/2ff42266-9de8-4af4-92ee-0ce5de8abe76" />

### ☁️ 坚果云同步（WebDAV）
- **首次登录弹窗**：输入坚果云服务器地址、账号、应用密码（支持记住密码）
- **静默自动连接**：下次启动自动尝试连接，右上角显示云状态图标（🟢 已连接 / ⚪ 未连接）
- **上云**：将当前所有记录导出为 Excel 表格，上传至坚果云（自动覆盖旧文件）
- **读云**：从坚果云下载 Excel 表格，解析并合并到本地记录
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/80dc792f-a5c6-4cc3-b268-df7a2aceab7b" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/2ab09cc4-231d-4a53-93ea-6d9635d22ba4" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/fcae6789-c1ce-4912-8166-92aa6cc5009a" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/63200f50-a11d-4794-8bf9-a92db862ac2b" />

### 📎 Excel 导入/导出
- **导出**：生成标准 CSV 文件（UTF-8 with BOM），可用 Excel / WPS 打开
- **导入**：从本地或云端读取 CSV 文件，恢复数据
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/ac089766-e3f8-4972-887b-ef16e2610836" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/c5e1cea3-ec3b-4bb4-9b5a-283e1b4f4b8b" />
---

## 🎨 主题与交互
- 内置 **5 套精美主题**（远山青、萤石黑、珠玉白、活力橙、全透明）
- 响应式布局，适配 Windows 桌面和 Android 手机
- 平滑动画与现代化圆角设计
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/3177f08d-944b-4c0a-be93-543b62896bce" />

---

## 🖥️ 技术栈

| 技术 | 用途 |
|------|------|
| **Flutter 3.22** | 跨平台 UI 框架 |
| **Dart** | 业务逻辑 |
| **SharedPreferences** | 本地配置与数据存储 |
| **path_provider** | 文件路径管理 |
| **http** | WebDAV 网络请求 |
| **intl** | 日期格式化 |
| **provider** | 状态管理 |

---

## 📦 下载与安装

### Windows 用户
1. 下载最新版 `Releases`
2. 解压到任意文件夹
3. 免安装，直接双击 `fitness_tracker.exe` 运行,可创建桌面快捷方式

### 从源码构建
```bash
从本仓库下载.dart和.yaml文件，在当前目录进入命令行（以下为示例）：
cd fitness_tracker
flutter pub get
flutter run -d windows   # 或 flutter run -d android
```

---

## ☁️ 坚果云配置指南

1. 登录 [坚果云网页版](https://www.jianguoyun.com)
2. 点击右上角账户 → **账户信息** → **安全选项**
3. 在 **第三方应用管理** 中点击 **添加应用**，名称任意（如：FitnessTracker）
4. 复制生成的 **应用密码**（不是登录密码）
5. 首次运行程序时，点击右上角云朵图标，填写：
   - 服务器地址：`https://dav.jianguoyun.com/dav/`
   - 账户邮箱：你的坚果云注册邮箱
   - 应用密码：上一步生成的密码
6. 勾选“记住密码”后，下次启动自动连接

> ⚠️ 注意：请勿将真实密码提交到代码仓库！本仓库示例已脱敏。

---

## 🛠️ 开发与贡献

### 目录结构
```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型（WorkoutRecord, WorkoutProject）
├── providers/                # 状态管理（WorkoutProvider, ThemeProvider）
├── services/                 # 核心服务（ExcelCSVService, NutstoreService）
└── screens/                  # 页面（MainScreen, HistoryScreen）
```

### 本地运行调试
- Windows：`flutter run -d windows`
- Android：连接手机后 `flutter run`

### 打包发布
```bash
# Windows 可执行文件
flutter build windows --release

# Android APK
flutter build apk --release
```

### 贡献指南
欢迎提交 Issue 和 Pull Request。请确保代码符合 `flutter format` 规范。

---

## 📄 开源协议
本项目采用 **MIT 协议**，详情见 [LICENSE](https://opensource.org/license/mit) 文件。

---

## 🙏 致谢
- 坚果云提供稳定的 WebDAV 服务
- Flutter 社区提供优秀的跨平台方案

---

## 📮 联系方式
如有问题或建议，请提交 [GitHub Issues](https://github.com/MrKedow/Fitness-Tracker/issues)。

**开始记录你的健身旅程吧！** 💪
