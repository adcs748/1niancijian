# 四六级英语（EnglishCoach）· iOS 原生版

面向大学英语四、六级备考的原生 iOS 应用（SwiftUI，iOS 17+）。本轮已把 Web 原型中的全部功能同步到 iOS 工程，包括阅读工具栏、长按组句语法分析、收藏夹、自动播放、相册壁纸、组件底层图案、可定制开机动画与四六级真题题库。

## 功能

- **导入文章**：粘贴文本、从「文件」导入 `.txt/.md`，或**图片英文识别（OCR）**。
- **逐段翻译**：一键翻译全文、进度提示、显示/隐藏译文、重新翻译。
- **阅读工具栏**：字号增减、深色/浅色切换、阅读模式（锁定单词选中）、翻译、朗读、收藏夹、更多。
- **单词交互**：
  - 单击单词 → 释义卡片（内置四六级词典优先，在线翻译兜底）；
  - 长按单词约 0.5 秒 → 进入选词模式，继续点击其他单词扩展选区；
  - 底部浮层显示原文、译文、主谓宾/表语/状语与句型，可收藏句子或批量收藏单词。
- **收藏夹**：单词与句子统一管理，支持搜索、发音、查看句子语法详情、移除；旧版生词本会自动迁移。
- **词汇学习**：四级 / 六级 / 收藏夹三个标签，按单词或释义搜索，行内发音。
- **自动播放**：听四/六级单词或朗读文章；支持循环、播放间隔（0.5/1/2 秒）、定时停止（5/10/20/30 分钟）与**起始位置**（可从第 N 项开始）；底部播放条可暂停/继续/停止。
- **外观定制**：
  - 从相册选择主界面壁纸，透明度 0–100%；
  - 每个可交互组件（卡片、工具栏按钮、段落卡、词条、搜索栏、导入控件、题库条目）可单独设置底层图案与透明度；
  - 编辑模式点击组件即可替换，顶部有「完成」提示条。
- **开机动画**：
  - 支持 JPG / PNG / GIF（GIF 保留动画）；
  - 尺寸 20%–100% 或铺满、时长 0.5–5 秒、每次启动播放开关、预览；
  - 页面启动时自动播放并淡出。
- **真题题库**：
   - 内置 3 篇原创模拟练习（含预置译文）；
   - 2016–2026 历年真题目录索引（126 条，仅目录）；
   - 官方大纲 / 试卷结构 / 成绩查询入口；
   - 用户自行导入已合法获取的真题，进入统一阅读器。
- **安全备份（客户授权）**：
   - 用户勾选同意后，读取**经授权的照片库**最近照片，或通过文件选择器主动选择文档；
   - 逐个上传到**用户/客户自己的服务器**（可配置地址与 Token）；
   - 备份记录保存在本机，可查看批次、文件数量、大小与状态；
   - 配套管理台 `backup-console.html` 可浏览服务器上的批次、文件清单并下载（用于客户数据追回）。
- **数据导出**：外观设置底部勾选「文章与图片识别记录 / 收藏夹 / 外观配置」，生成 `一念词间-数据包-YYYYMMDD.json`，通过系统分享保存；可用 `web-preview/viewer.html` 查看。
- **存储与内存**：首页「存储与内存」查看当前运行内存、手机存储总量/已用/可用、Documents 与外观图片占用，以及文章/收藏/词条数量。

## 安全备份与服务器

- 服务器示例位于 `backup-server/`（Node.js / Express），接口：
  - `POST /api/backups/:batchId/files`（multipart 上传单个文件）
  - `GET /api/backups`（批次列表）
  - `GET /api/backups/:batchId`（文件清单）
  - `GET /api/backups/:batchId/files/:name`（下载）
- 鉴权：请求头 `Authorization: Bearer <TOKEN>`，`TOKEN` 由环境变量提供，未设置将拒绝启动。
- 启动：`TOKEN=换成长随机串 DATA_DIR=./data npm start`（默认端口 8787），建议前置 HTTPS 反向代理。
- 管理台：浏览器打开 `web-preview/backup-console.html`，填入服务器地址与 Token 即可查看、下载。

**数据边界**：iOS 沙盒不允许 App 读取“所有手机文件”。可备份范围仅限：授权照片/视频库、用户主动选中的文档、App 自身数据。不会扫描其他 App、短信、通讯录或系统文件；所有上传都在用户勾选同意后发生。

## 运行环境

- macOS + **Xcode 16 或更高版本**（工程使用文件夹同步格式）；
- iOS 17.0+ 真机或模拟器；
- 在线翻译需要联网；发音使用系统语音。

## 在 Mac 上运行

1. 把整个项目目录（`EnglishCoach.xcodeproj` 与 `EnglishCoach/`）拷贝到 Mac。
2. 双击 `EnglishCoach.xcodeproj`。
3. 选中 `EnglishCoach` target → `Signing & Capabilities`：
   - 勾选 `Automatically manage signing`；
   - 选择你的 Apple ID / Team；
   - 把 `PRODUCT_BUNDLE_IDENTIFIER`（默认 `com.example.EnglishCoach`）改成你自己的唯一标识。
4. 连接 iPhone（需在手机上信任开发者），选择该设备，按 `Cmd + R` 安装运行。
   - 使用免费 Apple ID 时，签名有效期 7 天，到期重新运行即可。
5. 模拟器同样可直接运行（相册选图使用模拟器自带图片）。

## 生成可安装的 iPhone 应用（IPA）

1. Xcode 顶部选择 `Any iOS Device (arm64)`；
2. `Product → Archive`；
3. 在 Organizer 中 `Distribute App`：
   - 开发调试：`Development`；
   - 真机分发：`Ad Hoc`（需登记设备 UDID）；
   - 上架/TestFlight：`App Store Connect`（需付费开发者账号）。
4. 导出 `.ipa` 后可通过 Apple Configurator、AltStore、TrollStore（视设备与系统）或 TestFlight 安装。

> 本仓库是在 Windows 环境生成的，**无法在本机执行 Xcode 编译或导出 IPA**。上面的静态检查已通过，但最终编译需在 Mac 上完成；如有报错请回传日志。

### 没有 Mac 怎么办

可用 macOS 云构建服务（如 MacinCloud、Codemagic、GitHub Actions 的 macOS runner）打开/构建该工程，或借用一台 Mac。仅靠 Windows 无法生成签名后的 iOS 应用。

仓库已内置一键云构建：把项目推到 GitHub 后，在 **Actions → 构建 iOS 安装包 → Run workflow** 即可产出未签名 IPA（`.github/workflows/build-ipa.yml`），再用 Sideloadly / AltStore 自签安装到 iPhone。Mac 上也可运行 `scripts/build-ipa.sh` 一键出包。

> **完整、通俗的安装教程见 [`打包与安装指南.md`](打包与安装指南.md)**，包含“没 Mac 用 GitHub + Sideloadly”“有 Mac 用 Xcode”“付费账号 TestFlight”三条路线与常见问题。

## 工程结构

```
EnglishCoach/
├── EnglishCoachApp.swift      App 入口、环境注入、主题
├── Models.swift               数据模型、段落解析、题库索引与模拟题
├── Support.swift              品牌色、分词/分句、语法分析、FlowLayout、
│                              GIF 播放、组件皮肤修饰器、Toast
├── Stores.swift               文章/词典/收藏/外观存储、翻译、语音播放器
├── RootView.swift             根视图、启动动画、播放条、皮肤编辑面板
├── BackupService.swift        安全备份（照片授权、multipart 上传、记录持久化）
├── StorageStats.swift         内存/存储占用统计（resident、磁盘、目录大小）
└── Views/
    ├── HomeView.swift         首页（壁纸、导入、题库、今日词汇、文章、安全备份、存储与内存）
    ├── ReaderView.swift       阅读器（工具栏、选词、翻译）
    ├── VocabularyView.swift   词汇 / 收藏夹 / 自动播放
    ├── AppearanceView.swift   壁纸 / 启动动画 / 组件图案 / 数据导出
    ├── QuestionBankView.swift 真题题库
    ├── BackupView.swift       安全备份页
    ├── StorageInfoView.swift  存储与内存详情页
    └── SharedViews.swift      单词卡、选区浮层、播放设置、导入页（含 OCR）等
EnglishCoach/Resources/
├── cet4_words.txt             四级词库（543 词）
└── cet6_words.txt             六级词库（458 词）
```

## 数据存储

- 文章：`Documents/articles.json`
- 收藏夹：`Documents/favorites.json`（首次启动自动迁移旧 `wordbook.json`）
- 翻译缓存：`Documents/translation-cache.json`
- 外观：`Documents/Appearance/appearance.json` + 壁纸/皮肤/启动图文件
- 备份记录：`Documents/backup-records.json` + 备份设置（服务器地址/Token）
- 设置（字号、主题、阅读模式、译文显示）：`@AppStorage`

## 题库与版权

四六级真题版权归教育部教育考试院。应用**不内置未授权的真题全文**：

- 题库只提供目录索引与官方公开资料链接（中国教育考试网）；
- 模拟练习为原创内容；
- 真题正文请通过官方或授权渠道获取后，使用「导入真题」自行导入。

官方来源：<https://cet.neea.edu.cn/>

## 已知限制

- 语法分析为本地启发式规则，复杂从句/并列/双宾/宾补可能判断不完整，界面标注「仅供参考」。
- GIF 启动图限制 1.5MB（保留动画，不做压缩）；JPG/PNG 会压缩到最长边 900px。
- 在线翻译依赖 Google / MyMemory 免费接口，可能因网络或限流失败，失败时会提示。
- 组件皮肤、壁纸、启动图均保存在本机，不会上传。
- 安全备份只上传用户勾选/授权的内容；服务器需自行部署并妥善保管 Token 与数据。
- 图片 OCR 使用本机 Vision 框架离线识别，中英混排与低清晰度图片可能识别不全，可改用粘贴文本。
- 当前 iOS 端已同步全部主要功能：阅读工具栏、组句语法、收藏夹、自动播放（含起始位置）、外观定制、开机动画、题库、应用图标、图片 OCR、数据导出与安全备份。
- 本轮为一次性同步，尚未在 Xcode 中实际编译；如遇编译错误，按报错文件行号反馈即可快速修复。