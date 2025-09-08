VoiceboxAI — 日语工作友好润色助手（macOS）

概述
- 原生 SwiftUI macOS 小窗工具：始终置顶、输入区 + 输出区、极简苹果风。
- 任何语言输入（中/英/混合/蹩脚日语）→ 生成可直接发 Slack 的自然日语：不太正式、不太随意。
- 后端直连 Google Gemini（默认可改：gemini-2.5-flash-lite）。

也提供 Electron 版本（免 Xcode，本地或 CI 打包 DMG）。

快速开始
方式 A：原生 SwiftUI（需要 Xcode）
1) 用 Xcode 新建 macOS App（SwiftUI），名称：VoiceboxAI。
2) 复制 `VoiceboxAIApp` 目录下所有 Swift 源码到工程 Target。
3) 在 Signing & Capabilities 勾选 App Sandbox → Network → Outgoing。
4) 运行后在 设置 填 API Key，模型默认 `gemini-2.5-flash-lite`。

方式 B：Electron（免 Xcode，本地或 CI 打包 DMG）
本地打包：
- 需要 Node.js (>=18)。在 `electron` 目录执行：
  - `npm ci`
  - `npm run dev`（开发模式）
  - `npm run dist`（生成 `.dmg` 在 `electron/dist/`）

GitHub Actions 产出 DMG（无需本地构建）：
1) 将仓库推到 GitHub。
2) 在仓库的 Actions 页面启用并手动运行工作流 “Build macOS DMG (Electron)”。
3) 成功后在该 workflow 的 run 页面下载构建产物（`.dmg`）。

Electron 版本设置 API Key：点击窗口右上角设置图标 → 保存（默认保存到应用本地配置，非系统钥匙串）。

功能说明
- 置顶小窗：窗口始终浮在最上层，方便随手用。
- 一键润色：点击「转成日语（Slack 语气）」即可调用 Gemini 生成结果。
- 复制结果：点击复制按钮将结果放入剪贴板。
- 设置：
  - API Key 安全保存到 Keychain。
  - 自定义模型名与生成参数（温度等）。

Google Gemini API 准备
- 前往 Google AI Studio 创建 API Key（需开启计费）。
- 在设置页粘贴到本 App。
- 默认模型为 `gemini-2.5-flash-lite`；如不可用，可尝试 `gemini-2.0-flash-lite` 或 `gemini-1.5-flash`。

注意
- 本项目不内置 Xcode 工程文件（.xcodeproj），请按「快速开始」用 Xcode 新建后拷入源码。
- 若希望上架或分发，请根据你的签名、沙盒及权限策略自行调整。
- Electron 版本默认未签名，首次打开需通过 右键 → 打开 或 系统设置允许。

可选增强
- 全局快捷键呼出/隐藏窗口。
- 菜单栏图标与弹出面板。
- Slack API 直发（当前为复制即可粘贴到 Slack）。
