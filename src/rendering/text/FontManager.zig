const std = @import("std");

pub const FontInfo = struct {
    family: []const u8,
    size: f32,
    weight: u16,
    style: enum { normal, italic, bold, bold_italic },
    fallback_chain: [][]const u8,
};

pub const FontManager = struct {
    allocator: std.mem.Allocator,
    fonts: std.StringHashMap(FontInfo),
    default_size: f32,

    pub fn init(allocator: std.mem.Allocator) FontManager {
        return FontManager{
            .allocator = allocator,
            .fonts = std.StringHashMap(FontInfo).init(allocator),
            .default_size = 14.0,
        };
    }

    pub fn deinit(self: *FontManager) void {
        self.fonts.deinit();
    }

    pub fn register(self: *FontManager, name: []const u8, info: FontInfo) !void {
        try self.fonts.put(name, info);
    }

    pub fn get(self: *const FontManager, name: []const u8) ?FontInfo {
        return self.fonts.get(name);
    }

    pub fn getFallbackChain(self: *const FontManager, is_cjk: bool) [][]const u8 {
        if (is_cjk) {
            return &.{
                "Sarasa Gothic",
                "Noto Sans CJK SC",
                "WenQuanYi Micro Hei",
                "PingFang SC",
                "Microsoft YaHei",
                "SimHei",
            };
        }
        return &.{
            "JetBrains Mono",
            "Fira Code",
            "Source Code Pro",
            "Cascadia Code",
            "monospace",
        };
    }
};
