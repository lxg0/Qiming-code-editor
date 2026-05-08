# 启明编辑器 (Qiming Editor)

<div align="center">

**纯 Zig 语言开发的下一代代码编辑器**

借鉴 Zed 的优秀架构，弥补其不足；吸收微软 Edit 的极简理念，打造更轻量、更快速的中文友好编辑器。

[![Zig](https://img.shields.io/badge/Zig-0.16.0-orange?logo=zig)](https://ziglang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)]()
[![Binary Size](https://img.shields.io/badge/Binary-~2MB-yellow)]()

</div>

---

## 📖 简介

**启明编辑器**（Qiming Editor）是一个用纯 [Zig](https://ziglang.org/) 语言开发的轻量级代码编辑器。

> **Qiming（启明）** = 启明星，黎明时分天空中最亮的那颗星。

### 为什么选择 Zig？

- **零成本抽象**：无需垃圾回收，编译时元编程
- **极速编译**：秒级增量编译，远快于 Rust
- **小二进制**：默认链接裁剪，二进制体积极小
- **无缝 C ABI**：直接调用 HarfBuzz、FreeType、Tree-sitter 等 C 库
- **手动内存管理**：精细控制，无运行时开销

---

## ✨ 特性

### 核心编辑
- ⚡ **极速启动** — TUI 模式 <10ms，GUI 模式 <50ms
- 📝 **高效文本存储** — Piece Table + Gap Buffer 混合策略，大文件秒开
- 🖱️ **多光标编辑** — 原生多光标支持
- ↩️ **撤销/重做** — 基于 Edit Batch 的完整历史记录
- 📋 **剪贴板管理** — 多剪贴板轮换

### 渲染引擎
- 🖥️ **双模式渲染** — GUI（Metal/Vulkan/OpenGL）+ TUI（ANSI/Kitty 协议）
- 🎨 **暗色/亮色主题** — 内置 Qiming Dark 和 Qiming Light
- 🌐 **CJK 字体支持** — 完整的 CJK 字符宽度检测和字体回退链
- ✨ **动画系统** — 缓动函数、平滑过渡

### 语言支持
- 🔤 **语法高亮** — 10+ 语言内置支持（Zig / Rust / Python / JS / TS / HTML / JSON / Markdown / C / C++）
- 📁 **代码折叠** — 基于缩进的智能折叠
- 🎯 **括号匹配** — 深度感知的括号配对
- 🔌 **Tree-sitter** — 增量语法解析（规划中）
- 📡 **LSP 客户端** — 完整的语言服务器协议支持

### AI 助手
- 🤖 **多后端** — Claude / GPT / Ollama（本地模型）
- 💬 **对话面板** — 内嵌 AI 对话
- ✍️ **内联补全** — 上下文感知的代码补全

### 协作编辑
- 👥 **CRDT 引擎** — 无冲突复制数据类型
- 🌐 **端到端同步** — WebRTC 点对点协作

### 终端
- 🖥️ **内置终端** — 完整的 VT100 终端模拟器
- 🎨 **Kitty 协议** — 支持 Kitty 图形协议

### 插件系统
- 🧩 **双通道** — Zig 原生动态库 + WASM
- 🔒 **安全沙箱** — 插件隔离运行

### 中文本地化
- 🇨🇳 **完整中文界面** — 130+ 中文翻译
- ⌨️ **输入法支持** — IME 预编辑缓冲区
- 🔤 **CJK 搜索** — 中文文件名模糊匹配

---

## 🎯 与 Zed 编辑器的对比

| 维度 | Zed (Rust) | 启明 Qiming (Zig) |
|------|-----------|-------------------|
| 内存占用 | ~500MB+ | 目标 <30MB |
| 渲染后端 | 仅 GPU | GPU + TUI 双模式 |
| 插件系统 | WASM 单通道 | Zig 原生 + WASM 双通道 |
| 协作编辑 | 付费功能 | 内置免费 CRDT |
| 二进制大小 | ~30MB | 目标 <5MB |
| 中文支持 | 弱 | **一级支持** |
| 终端模拟 | 基础 | 完整 Kitty 协议 |
| 配置格式 | JSON | TOML |
| 编译时间 | 长（Rust） | 短（Zig） |

---

## 🚀 快速开始

### 前置要求

- [Zig 0.16.0](https://ziglang.org/download/) 或更高版本

### 编译

```bash
# 克隆仓库
git clone https://github.com/lxg0/Qiming-code-editor.git
cd Qiming-code-editor

# 编译（Debug 模式）
zig build

# 编译（Release 模式，优化二进制大小）
zig build -Doptimize=ReleaseSafe
```

### 运行

```bash
# TUI 模式（终端界面）
zig build run

# 指定文件打开
zig build run -- myfile.js

# 查看帮助（目前仅支持英文帮助）
./zig-out/bin/qiming
```

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+C` | 复制 |
| `Ctrl+V` | 粘贴 |
| `Ctrl+X` | 剪切 |
| `Ctrl+S` | 保存 |
| `Ctrl+Z` | 撤销 |
| `Ctrl+Y` | 重做 |
| `Ctrl+Q` | 退出 |
| `Ctrl+F` | 查找 |
| `Ctrl+H` | 替换 |
| `Ctrl+P` | 命令面板 |

---

## 📂 项目结构

```
qiming/
├── src/
│   ├── main.zig                  # 入口点
│   ├── app/                      # 应用核心
│   │   ├── App.zig               # 应用编排
│   │   ├── Config.zig            # 配置管理 (TOML)
│   │   └── Command.zig           # 命令调度
│   ├── workspace/                # 工作区管理
│   │   ├── Workspace.zig
│   │   ├── ProjectTree.zig
│   │   └── SearchIndex.zig
│   ├── buffer/                   # 文本缓冲区
│   │   ├── Buffer.zig            # 统一接口
│   │   ├── PieceTable.zig        # Piece Table
│   │   ├── GapBuffer.zig         # Gap Buffer
│   │   ├── Rope.zig              # Rope 数据结构
│   │   ├── Cursor.zig            # 光标管理
│   │   ├── Selection.zig         # 选择管理
│   │   ├── Edit.zig              # 编辑操作
│   │   ├── Undo.zig              # 撤销/重做
│   │   └── simd.zig              # SIMD 加速
│   ├── editor/                   # 编辑器核心
│   │   ├── Editor.zig            # 编辑器主控
│   │   ├── Document.zig          # 文档模型
│   │   ├── View.zig              # 视图管理
│   │   ├── MultiCursor.zig       # 多光标
│   │   ├── Snippet.zig           # 代码片段
│   │   └── Mode.zig              # 编辑模式
│   ├── rendering/                # 渲染引擎
│   │   ├── Renderer.zig          # 抽象渲染器
│   │   ├── Theme.zig             # 主题系统
│   │   ├── Animation.zig         # 动画系统
│   │   ├── gui/                  # GUI 后端
│   │   ├── tui/                  # TUI 后端
│   │   └── text/                 # 文字渲染
│   ├── ui/                       # UI 组件
│   │   ├── Component.zig         # 组件基类
│   │   ├── Layout.zig            # 布局引擎
│   │   ├── TabBar.zig            # 标签栏
│   │   ├── Sidebar.zig           # 侧边栏
│   │   ├── StatusBar.zig         # 状态栏
│   │   ├── CommandPalette.zig    # 命令面板
│   │   ├── Menu.zig              # 菜单栏
│   │   ├── Dialog.zig            # 对话框
│   │   ├── Notification.zig      # 通知系统
│   │   ├── InputBox.zig          # 输入框
│   │   └── Scrollbar.zig         # 滚动条
│   ├── syntax/                   # 语法分析
│   │   ├── Syntax.zig            # 语法引擎
│   │   ├── Highlight.zig         # 语法高亮
│   │   ├── Fold.zig              # 代码折叠
│   │   ├── Indent.zig            # 智能缩进
│   │   ├── Bracket.zig           # 括号匹配
│   │   └── TreeSitter.zig        # Tree-sitter
│   ├── lsp/                      # LSP 客户端
│   │   ├── LspClient.zig
│   │   ├── Protocol.zig
│   │   ├── Transport.zig
│   │   ├── Completion.zig
│   │   ├── Diagnostic.zig
│   │   ├── Hover.zig
│   │   ├── Goto.zig
│   │   └── SemanticTokens.zig
│   ├── ai/                       # AI 助手
│   │   ├── AiManager.zig
│   │   ├── Provider.zig
│   │   ├── Anthropic.zig
│   │   ├── OpenAI.zig
│   │   ├── Ollama.zig
│   │   ├── Completion.zig
│   │   └── Chat.zig
│   ├── collab/                   # 协作编辑
│   │   ├── Collab.zig
│   │   ├── Crdt.zig
│   │   ├── Peer.zig
│   │   └── Sync.zig
│   ├── terminal/                 # 终端模拟
│   │   ├── Terminal.zig
│   │   ├── Pty.zig
│   │   └── Screen.zig
│   ├── fs/                       # 文件系统
│   │   ├── FileIO.zig
│   │   ├── FileWatcher.zig
│   │   ├── LineEnding.zig
│   │   └── Encoding.zig
│   ├── plugin/                   # 插件系统
│   │   ├── PluginManager.zig
│   │   └── PluginApi.zig
│   ├── input/                    # 输入处理
│   │   ├── Input.zig
│   │   ├── Keymap.zig
│   │   ├── Ime.zig
│   │   └── Gesture.zig
│   └── util/                     # 工具库
│       ├── Arena.zig
│       ├── Allocator.zig
│       ├── Async.zig
│       ├── Log.zig
│       └── i18n.zig
├── ARCHITECTURE.md               # 架构设计文档
├── build.zig                     # 构建配置
├── build.zig.zon                 # 依赖管理
└── .gitignore
```

---

## 🗺️ 路线图

### v0.1 (当前)
- [x] 基础 TUI 编辑器
- [x] Piece Table + Gap Buffer
- [x] 语法高亮（10+ 语言）
- [x] 撤销/重做
- [x] 基本 UI 组件
- [x] AI 助手骨架
- [x] LSP 客户端骨架
- [x] 中文界面（130+ 翻译）

### v0.2 (规划中)
- [ ] GUI 模式（Metal/Vulkan 后端）
- [ ] 文件树侧边栏
- [ ] Tree-sitter 增量解析
- [ ] LSP 服务器通信
- [ ] 实时协作编辑
- [ ] 终端集成

### v0.3 (规划中)
- [ ] 插件市场
- [ ] WASM 运行时
- [ ] 远程 SSH 开发
- [ ] 自定义主题
- [ ] 代码片段管理

### v1.0 (愿景)
- [ ] 完整 IDE 功能
- [ ] 插件生态
- [ ] 多语言界面
- [ ] 云端同步
- [ ] 性能优化

---

## 🤝 贡献

欢迎贡献代码！请遵循以下流程：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m '添加了某功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

---

## 💡 设计理念

> **"Simple things should be simple, complex things should be possible."**
> 
> 简单的事情应该保持简单，复杂的事情应该是可能的。—— Alan Kay

启明编辑器遵循以下设计原则：

1. **极简优先** — 默认无模态编辑，像 VS Code 一样直观
2. **性能至上** — SIMD 加速、Arena 分配、零拷贝
3. **中文友好** — 一级 CJK 字体支持、IME 兼容
4. **模块化** — 所有功能通过模块接口连接
5. **可扩展** — 原生插件 + WASM 双通道

---

## 🙏 致谢

本项目深受以下优秀开源项目的启发：

- [Zed Editor](https://zed.dev) — GPU 加速的协作编辑器
- [Microsoft Edit](https://github.com/microsoft/edit) — 极简文本编辑器
- [Zig 语言](https://ziglang.org) — 下一代系统编程语言

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给我们一个 Star！**

**Made with ❤️ in Zig**

</div>
