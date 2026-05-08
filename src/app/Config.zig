const std = @import("std");

pub const FONT_SIZE_MIN: f32 = 8.0;
pub const FONT_SIZE_MAX: f32 = 72.0;
pub const FONT_SIZE_DEFAULT: f32 = 14.0;

pub const Config = struct {
    allocator: std.mem.Allocator,
    // ── Editor ────────────────────────────────────────────────────────────────
    tab_size: u8 = 4,
    use_tabs: bool = false,
    word_wrap: bool = true,
    line_numbers: bool = true,
    minimap: bool = true,

    // ── Font (clamped between MIN and MAX) ─────────────────────────────────────
    font_size: f32 = FONT_SIZE_DEFAULT,
    font_family: []const u8 = "JetBrains Mono",
    cjk_font_family: []const u8 = "Sarasa Gothic",

    // ── UI layout (VS Code-style) ──────────────────────────────────────────────
    sidebar_visible: bool = true,
    sidebar_width: f32 = 260.0,
    activity_bar_visible: bool = true,
    activity_bar_width: f32 = 48.0,
    bottom_panel_visible: bool = false,
    bottom_panel_height: f32 = 200.0,
    status_bar_visible: bool = true,
    status_bar_height: f32 = 22.0,
    tab_bar_height: f32 = 35.0,
    breadcrumb_visible: bool = false,
    breadcrumb_height: f32 = 22.0,

    // ── Theme ──────────────────────────────────────────────────────────────────
    theme: []const u8 = "qiming-dark",
    locale: []const u8 = "zh-CN",
    auto_save: bool = true,
    auto_save_interval_ms: u64 = 3000,

    // ── Terminal ───────────────────────────────────────────────────────────────
    terminal_font_size: f32 = 13,
    terminal_scrollback: usize = 10000,

    // ── AI ─────────────────────────────────────────────────────────────────────
    ai_provider: []const u8 = "claude",
    ai_model: []const u8 = "claude-sonnet-4-20250514",
    ai_api_key: []const u8 = "",
    ai_enabled: bool = false,

    // ── LSP ────────────────────────────────────────────────────────────────────
    lsp_enabled: bool = true,

    // ── Plugin (VS Code-compatible via WASM) ────────────────────────────────────
    plugins_dir: []const u8 = "~/.config/qiming/plugins",
    vscode_extensions_dir: []const u8 = "~/.vscode/extensions",
    wasm_plugin_enabled: bool = true,
    // Built-in JS→WASM converter path (expects QuickJS WASM binary)
    js2wasm_runtime_path: []const u8 = "",

    pub fn init(allocator: std.mem.Allocator) Config {
        return Config{
            .allocator = allocator,
            .font_family = "JetBrains Mono",
            .cjk_font_family = "Sarasa Gothic",
            .theme = "qiming-dark",
            .locale = "zh-CN",
            .ai_provider = "claude",
            .ai_model = "claude-sonnet-4-20250514",
            .ai_api_key = "",
            .plugins_dir = "~/.config/qiming/plugins",
        };
    }

    pub fn deinit(self: *Config) void {
        _ = self;
    }

    /// Clamp font_size, returning the clamped value.
    pub fn clampFontSize(size: f32) f32 {
        return @max(FONT_SIZE_MIN, @min(FONT_SIZE_MAX, size));
    }

    /// Zoom in by 1pt, clamped.
    pub fn zoomIn(self: *Config) f32 {
        self.font_size = clampFontSize(self.font_size + 1.0);
        return self.font_size;
    }

    /// Zoom out by 1pt, clamped.
    pub fn zoomOut(self: *Config) f32 {
        self.font_size = clampFontSize(self.font_size - 1.0);
        return self.font_size;
    }

    /// Reset zoom to default.
    pub fn zoomReset(self: *Config) void {
        self.font_size = FONT_SIZE_DEFAULT;
    }

    pub fn toggleSidebar(self: *Config) void {
        self.sidebar_visible = !self.sidebar_visible;
    }

    pub fn toggleBottomPanel(self: *Config) void {
        self.bottom_panel_visible = !self.bottom_panel_visible;
    }

    pub fn load(self: *Config, path: []const u8) !void {
        _ = self; _ = path;
    }

    pub fn save(self: *const Config, path: []const u8) !void {
        _ = self; _ = path;
    }
};
