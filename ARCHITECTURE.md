# 启明编辑器 (Qiming Editor) - 全架构设计

> **Qiming (启明)** = 启明星，代表黎明的第一颗星。用纯 Zig 语言打造的下一代代码编辑器。

---

## 一、Zed 编辑器不足分析

| # | 问题 | 严重度 | Zig 项目中的优化方案 |
|---|------|--------|---------------------|
| 1 | **内存占用高** (500MB+) — GPUI 渲染管线 + Rust 所有权模型导致大量堆分配 | 高 | 基于 Arena 分配器 + 自定义 BumpAllocator，单次分配多次使用；PieceTable 替代纯 Rope 减少碎片 |
| 2 | **GPU 强依赖** — 无 GPU 环境完全不可用 | 高 | 双渲染后端：TUI (ANSI/Kitty 协议) + GUI (Mach/SDL2/Metal)，自动检测降级 |
| 3 | **插件生态薄弱** — WASM 插件系统文档少、API 不稳定 | 中 | Zig 原生插件系统 (动态加载 .so/.dylib) + WASM 双通道，提供完整 C API |
| 4 | **CJK/中文支持差** — 字体回退不完善、输入法兼容差 | 高 | 一级 UTF-8 支持，内置 HarfBuzz 文本整形，IME 预编辑缓冲区，中文字体优先级回退链 |
| 5 | **协作功能收费** — 实时协作是付费墙后功能 | 中 | CRDT (RGA 算法) 内置免费，点对点 WebRTC + 中继服务器可选 |
| 6 | **终端模拟器弱** — 不支持 Kitty 图形协议、无六色支持 | 中 | 完整 xterm 兼容 + Kitty 图形协议 + sixel，支持真彩色 + 连字 |
| 7 | **多显示器 DPI** — 不同缩放比例显示器间拖拽异常 | 中 | 独立 per-window DPI 感知，动态重新光栅化字体 |
| 8 | **远程开发缺失** — 无内置 Remote SSH | 中 | 内置 SSH 客户端 + 远程代理协议，自动文件同步 |
| 9 | **搜索性能** — 大项目 (>10万文件) 模糊搜索慢 | 低 | SIMD 加速 ripgrep 风格搜索 + 异步索引 |
| 10 | **配置复杂** — JSON 配置冗长，缺少 GUI 配置界面 | 低 | TOML 配置 + 内置图形化配置面板 |

---

## 二、Microsoft Edit 优点借鉴

| 优点 | 描述 | 在 Qiming 中的采纳 |
|------|------|-------------------|
| **极简 Buffer** | 单块连续 UTF-8 字节数组 | PieceTable 保留此理念作为后备模式 |
| **SIMD 加速** | 100GB/s+ 行搜索 | 核心搜索路径全部 SIMD 优化 |
| **快速启动** | <5ms | 目标 <10ms (含 GUI) |
| **小二进制** | ~200KB | 目标 <2MB (含 GUI 后端) |
| **模式无关编辑** | 类 VS Code，非 Vim | 默认模式无关，Vim 模式作为可选插件 |

---

## 三、技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| 语言 | Zig 0.16.0 | 编译时元编程 + 无 GC + 零成本 C ABI |
| 构建系统 | Zig Build System | 单文件构建，无需 Make/CMake |
| 文本存储 | Piece Table + Rope 混合 | 根据文件大小自动切换 |
| GUI 渲染 | Mach Core (Metal/Vulkan/OpenGL) | 跨平台 GPU 渲染 |
| TUI 渲染 | ANSI + Kitty 协议 | 终端环境下自动切换 |
| 文本整形 | HarfBuzz (C ABI) | 复杂文本布局 (CJK/阿拉伯语) |
| 字体 | FreeType (C ABI) | 字体光栅化 |
| 语法分析 | Tree-sitter (C ABI) | 增量解析、容错语法树 |
| LSP | Zig 原生实现 | 语言服务器协议客户端 |
| 异步 I/O | Zig async + io_uring (Linux) | 零拷贝文件 I/O |
| 协作 | CRDT (RGA 算法) | 无冲突复制数据类型 |
| 插件 | Zig 动态库 + WASM | 双插件通道 |
| AI | Claude/GPT/本地 Ollama | 多提供商 AI 集成 |
| 配置 | TOML | 人性化配置格式 |

---

## 四、整体架构图

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Shell 层 (入口)                               │
│   main.zig ──→ CLI 参数解析 ──→ 模式选择 (gui/tui/headless)          │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
   ┌──────────┐          ┌──────────────┐        ┌──────────────┐
   │ GUI 模式  │          │  TUI 模式     │        │ Headless 模式 │
   │ (Mach)   │          │ (ANSI+Kitty) │        │ (Server/CI)  │
   └────┬─────┘          └──────┬───────┘        └──────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │   App 核心编排层       │
                    │  app/App.zig          │
                    └───────────┬───────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  workspace/   │    │   editor/        │    │   rendering/     │
│  工作区管理    │    │   编辑器核心      │    │   渲染抽象层      │
│  - 项目树     │    │  - 多文档        │    │  - GUI 后端      │
│  - 文件监视   │    │  - 多视图        │    │  - TUI 后端      │
│  - 搜索索引   │    │  - 标签页        │    │  - 主题系统      │
└───────┬───────┘    └────────┬─────────┘    └────────┬─────────┘
        │                    │                        │
        └────────────────────┼────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
   ┌──────────────────┐          ┌──────────────────┐
   │   buffer/        │          │   lsp/            │
   │   文本缓冲区      │          │   语言服务器       │
   │  - PieceTable   │          │  - LSP 客户端     │
   │  - Rope         │          │  - 诊断收集       │
   │  - 文本操作     │          │  - 补全提供       │
   │  - UTF-8 处理   │          │  - 符号导航       │
   └────────┬─────────┘          └────────┬─────────┘
            │                             │
            └──────────────┬──────────────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
            ▼                             ▼
   ┌──────────────────┐          ┌──────────────────┐
   │   syntax/        │          │   collab/        │
   │   语法分析        │          │   协作编辑         │
   │  - Tree-sitter  │          │  - CRDT 引擎     │
   │  - 语法高亮     │          │  - WebRTC 传输    │
   │  - 代码折叠     │          │  - 状态同步       │
   │  - 缩进计算     │          │  - 冲突解决       │
   └────────┬─────────┘          └────────┬─────────┘
            │                             │
            └──────────────┬──────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   ai/        │  │   terminal/  │  │   plugin/    │
│   AI 助手    │  │   终端模拟器  │  │   插件系统    │
│  - Claude   │  │  - PTY      │  │  - 加载器    │
│  - GPT      │  │  - ANSI     │  │  - API      │
│  - Ollama   │  │  - Kitty    │  │  - 沙箱     │
│  - 补全     │  │  - Sixel    │  │  - 市场     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 五、目录结构

```
qiming/
├── src/
│   ├── main.zig                  # 入口点
│   │
│   ├── app/                      # 应用核心
│   │   ├── App.zig               # 应用编排、生命周期
│   │   ├── Config.zig            # 配置管理 (TOML)
│   │   └── Command.zig           # 命令调度
│   │
│   ├── workspace/                # 工作区
│   │   ├── Workspace.zig         # 工作区管理
│   │   ├── ProjectTree.zig       # 项目文件树
│   │   ├── FileWatcher.zig       # 文件系统监视
│   │   └── SearchIndex.zig       # 全文搜索索引
│   │
│   ├── buffer/                   # 文本缓冲区层
│   │   ├── Buffer.zig            # 统一 Buffer 接口
│   │   ├── PieceTable.zig        # Piece Table 实现
│   │   ├── Rope.zig              # 增强 Rope 实现
│   │   ├── GapBuffer.zig         # Gap Buffer (小文件)
│   │   ├── Cursor.zig            # 光标管理
│   │   ├── Selection.zig         # 选择管理
│   │   ├── Edit.zig              # 编辑操作
│   │   ├── Undo.zig              # 撤销/重做
│   │   └── simd.zig              # SIMD 加速原语
│   │
│   ├── editor/                   # 编辑器核心
│   │   ├── Editor.zig            # 编辑器主控
│   │   ├── Document.zig          # 文档模型
│   │   ├── View.zig              # 视图管理
│   │   ├── MultiCursor.zig       # 多光标编辑
│   │   ├── Snippet.zig           # 代码片段
│   │   └── Mode.zig              # 编辑模式 (Normal/Vim)
│   │
│   ├── rendering/                # 渲染抽象层
│   │   ├── Renderer.zig          # 渲染器抽象接口
│   │   ├── gui/                  # GUI 渲染
│   │   │   ├── GuiRenderer.zig   # Mach/Metal 渲染器
│   │   │   ├── Surface.zig       # 渲染表面
│   │   │   ├── Pipeline.zig      # 渲染管线
│   │   │   └── Shader.zig        # 着色器管理
│   │   ├── tui/                  # TUI 渲染
│   │   │   ├── TuiRenderer.zig   # ANSI/Kitty 终端渲染
│   │   │   ├── Ansi.zig          # ANSI 转义码
│   │   │   └── Kitty.zig         # Kitty 图形协议
│   │   ├── text/                 # 文字渲染
│   │   │   ├── TextShaper.zig    # HarfBuzz 文本整形
│   │   │   ├── FontManager.zig   # 字体管理/回退
│   │   │   └── GlyphCache.zig    # 字形缓存
│   │   ├── Theme.zig             # 主题/配色方案
│   │   └── Animation.zig         # 动画系统
│   │
│   ├── ui/                       # UI 组件
│   │   ├── Component.zig         # UI 组件基类
│   │   ├── Layout.zig            # 布局引擎
│   │   ├── TabBar.zig            # 标签栏
│   │   ├── Sidebar.zig           # 侧边栏
│   │   ├── StatusBar.zig         # 状态栏
│   │   ├── CommandPalette.zig    # 命令面板
│   │   ├── Menu.zig              # 菜单栏
│   │   ├── Dialog.zig            # 对话框
│   │   ├── Notification.zig      # 通知提示
│   │   ├── InputBox.zig          # 输入框
│   │   └── Scrollbar.zig         # 滚动条
│   │
│   ├── syntax/                   # 语法分析
│   │   ├── Syntax.zig            # 语法引擎
│   │   ├── TreeSitter.zig        # Tree-sitter 绑定
│   │   ├── Highlight.zig         # 语法高亮
│   │   ├── Fold.zig              # 代码折叠
│   │   ├── Indent.zig            # 智能缩进
│   │   ├── Bracket.zig           # 括号匹配
│   │   └── languages/            # 语言特定配置
│   │       ├── zig.zig
│   │       ├── rust.zig
│   │       └── ...
│   │
│   ├── lsp/                      # LSP 客户端
│   │   ├── LspClient.zig         # LSP 客户端核心
│   │   ├── Protocol.zig          # LSP 协议类型
│   │   ├── Transport.zig         # 传输层 (stdio/tcp)
│   │   ├── Completion.zig        # 代码补全
│   │   ├── Diagnostic.zig        # 诊断/错误
│   │   ├── Hover.zig             # 悬停信息
│   │   ├── Goto.zig              # 跳转定义/引用
│   │   └── SemanticTokens.zig    # 语义高亮
│   │
│   ├── ai/                       # AI 助手
│   │   ├── AiManager.zig         # AI 管理器
│   │   ├── Provider.zig          # 提供商接口
│   │   ├── Anthropic.zig         # Claude API
│   │   ├── OpenAI.zig            # GPT API
│   │   ├── Ollama.zig            # 本地 Ollama
│   │   ├── Completion.zig        # 代码补全
│   │   └── Chat.zig              # 对话面板
│   │
│   ├── collab/                   # 协作编辑
│   │   ├── Collab.zig            # 协作引擎
│   │   ├── Crdt.zig              # CRDT 数据结构
│   │   ├── Peer.zig              # 对等节点
│   │   ├── Transport.zig         # WebRTC 传输
│   │   └── Sync.zig              # 状态同步
│   │
│   ├── terminal/                 # 终端模拟器
│   │   ├── Terminal.zig          # 终端模拟器
│   │   ├── Pty.zig               # PTY 伪终端
│   │   ├── Screen.zig            # 屏幕缓冲区
│   │   ├── AnsiParser.zig        # ANSI 解析器
│   │   └── KittyGraphics.zig     # Kitty 图形协议
│   │
│   ├── fs/                       # 文件系统
│   │   ├── FileIO.zig            # 文件读写
│   │   ├── FileWatcher.zig       # 文件变更监视
│   │   ├── LineEnding.zig        # 换行符处理
│   │   └── Encoding.zig          # 文件编码检测/转换
│   │
│   ├── plugin/                   # 插件系统
│   │   ├── PluginManager.zig     # 插件管理器
│   │   ├── PluginApi.zig         # 插件 API
│   │   ├── WasmRuntime.zig       # WASM 运行时
│   │   ├── NativeLoader.zig      # 动态库加载器
│   │   └── Sandbox.zig           # 安全沙箱
│   │
│   ├── input/                    # 输入处理
│   │   ├── Input.zig             # 输入事件循环
│   │   ├── Keymap.zig            # 键位映射
│   │   ├── Ime.zig               # 输入法编辑器 (IME)
│   │   └── Gesture.zig           # 手势识别
│   │
│   └── util/                     # 工具库
│       ├── Allocator.zig         # 自定义分配器
│       ├── Arena.zig             # Arena 分配器
│       ├── Async.zig             # 异步工具
│       ├── Log.zig               # 日志系统
│       └── i18n.zig              # 国际化/中文
│
├── build.zig                     # 构建配置
├── build.zig.zon                 # 依赖管理
├── config.toml                   # 默认配置
└── themes/                       # 主题目录
    ├── qiming-dark.toml
    └── qiming-light.toml
```

---

## 六、核心数据流

### 6.1 编辑数据流

```
按键输入 → Input.zig → Command.zig → Editor.zig
                                         │
                              ┌──────────┼──────────┐
                              ▼          ▼          ▼
                        Document.zig  Buffer.zig  Undo.zig
                              │          │
                              ▼          ▼
                        PieceTable/Rope  Edit 操作
                              │
                    ┌─────────┼─────────┐
                    ▼         ▼         ▼
              Syntax.zig  LspClient  AiManager
              (重新解析)  (通知变更)  (上下文更新)
                    │
                    ▼
              Renderer.zig
              (脏区域重绘)
```

### 6.2 渲染数据流

```
Renderer.zig (抽象层)
    │
    ├── GUI 模式:
    │   GuiRenderer → Surface → Pipeline → Metal/Vulkan → GPU
    │       │
    │       └── TextShaper (HarfBuzz) → GlyphCache → FontManager
    │
    └── TUI 模式:
        TuiRenderer → Ansi/Kitty → 终端 stdout
            │
            └── 简化的字型映射表
```

### 6.3 AI 数据流

```
用户触发 → AiManager
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
Claude     GPT      Ollama (本地)
    │         │         │
    └─────────┼─────────┘
              ▼
        Provider 接口
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
 Completion  Chat    CodeReview
    │         │         │
    └─────────┼─────────┘
              ▼
        Editor (应用结果)
```

---

## 七、中文/国际化设计

### 7.1 界面中文化

```zig
// src/util/i18n.zig
pub const Locale = enum {
    zh_CN,  // 简体中文
    zh_TW,  // 繁体中文
    en_US,  // 英语
    ja_JP,  // 日语
    ko_KR,  // 韩语
};

pub const I18n = struct {
    locale: Locale,
    // 编译时加载对应语言的翻译文件
    translations: Translations,
};
```

### 7.2 中文字体支持

- 内置字体回退链: `Sarasa Gothic → Noto Sans CJK → WenQuanYi → 系统默认`
- HarfBuzz 文本整形保证连字、组合字符正确
- IME (输入法) 预编辑缓冲区独立管理

### 7.3 中文搜索

- 内置 jieba 分词 (编译时嵌入)
- 拼音搜索支持
- 模糊匹配中文文件名

---

## 八、性能目标

| 指标 | 目标 | 测量方式 |
|------|------|---------|
| 冷启动时间 | <50ms (GUI), <10ms (TUI) | `time qiming --bench` |
| 内存占用 (空项目) | <30MB | RSS 测量 |
| 打开 100MB 文件 | <1s | 滚动至底部时间 |
| 输入延迟 | <8ms (端到端) | Input→Render 时间差 |
| 语法高亮延迟 | <16ms (初次), <1ms (增量) | Tree-sitter 解析时间 |
| FPS (GUI) | 稳定 60fps (120fps ProMotion) | 帧时间测量 |
| 搜索 10 万文件 | <500ms | ripgrep 风格搜索 |

---

## 九、与 Zed 关键差异

| 维度 | Zed (Rust) | Qiming (Zig) |
|------|-----------|-------------|
| 内存模型 | 所有权 + 引用计数 | 手动管理 + Arena |
| 文本存储 | Rope 为主 | PieceTable + Rope 混合 |
| 渲染 | 仅 GPU (GPUI) | GPU + TUI 双模式 |
| 插件 | WASM 单通道 | Zig 原生 + WASM 双通道 |
| 协作 | 付费 | 内置免费 CRDT |
| 配置 | JSON | TOML |
| 二进制大小 | ~30MB | 目标 <5MB |
| 编译时间 | 长 (Rust 编译链) | 短 (Zig 编译链) |
| 中文支持 | 弱 | 一级支持 |
```

