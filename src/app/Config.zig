const std = @import("std");

pub const Config = struct {
    allocator: std.mem.Allocator,
    // Editor
    tab_size: u8 = 4,
    use_tabs: bool = false,
    word_wrap: bool = true,
    line_numbers: bool = true,
    minimap: bool = true,
    font_size: f32 = 14,
    font_family: []const u8 = "JetBrains Mono",
    cjk_font_family: []const u8 = "Sarasa Gothic",
    theme: []const u8 = "qiming-dark",
    locale: []const u8 = "zh-CN",
    auto_save: bool = true,
    auto_save_interval_ms: u64 = 3000,
    // UI
    sidebar_width: f32 = 250,
    show_gutter: bool = true,
    show_indent_guide: bool = true,
    // Terminal
    terminal_font_size: f32 = 13,
    terminal_scrollback: usize = 10000,
    // AI
    ai_provider: []const u8 = "claude",
    ai_model: []const u8 = "claude-sonnet-4-20250514",
    ai_api_key: []const u8 = "",
    ai_enabled: bool = false,
    // LSP
    lsp_enabled: bool = true,
    // Plugin
    plugins_dir: []const u8 = "~/.config/qiming/plugins",

    pub fn init(allocator: std.mem.Allocator) Config {
        return Config{ .allocator = allocator, .font_family = "JetBrains Mono", .cjk_font_family = "Sarasa Gothic", .theme = "qiming-dark", .locale = "zh-CN", .ai_provider = "claude", .ai_model = "claude-sonnet-4-20250514", .ai_api_key = "", .plugins_dir = "~/.config/qiming/plugins" };
    }

    pub fn deinit(self: *Config) void {
        _ = self;
    }

    pub fn load(self: *Config, path: []const u8) !void {
        _ = self; _ = path;
    }

    pub fn save(self: *const Config, path: []const u8) !void {
        _ = self; _ = path;
    }
};
