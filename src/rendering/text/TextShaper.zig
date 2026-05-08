const std = @import("std");

pub const GlyphInfo = struct {
    codepoint: u21,
    cluster: u32,
    x_advance: f32,
    y_advance: f32,
    x_offset: f32,
    y_offset: f32,
    width: f32,
    height: f32,
    is_cjk: bool,
};

pub const ShapedLine = struct {
    allocator: std.mem.Allocator,
    glyphs: std.array_list.Managed(GlyphInfo),
    width: f32,
    height: f32,

    pub fn init(allocator: std.mem.Allocator) ShapedLine {
        return ShapedLine{
            .allocator = allocator,
            .glyphs = std.array_list.Managed(GlyphInfo).init(allocator),
            .width = 0,
            .height = 0,
        };
    }

    pub fn deinit(self: *ShapedLine) void {
        self.glyphs.deinit();
    }
};

pub const TextShaper = struct {
    allocator: std.mem.Allocator,
    font_size: f32,
    tab_width: usize,

    pub fn init(allocator: std.mem.Allocator) TextShaper {
        return TextShaper{
            .allocator = allocator,
            .font_size = 14.0,
            .tab_width = 4,
        };
    }

    pub fn setFontSize(self: *TextShaper, size: f32) void {
        self.font_size = size;
    }

    pub fn shapeLine(self: *TextShaper, text: []const u8, tab_size: usize) !ShapedLine {
        var line = ShapedLine.init(self.allocator);
        errdefer line.deinit();
        const char_width = self.font_size * 0.6;
        const char_height = self.font_size;
        var x: f32 = 0;
        var i: usize = 0;
        while (i < text.len) {
            const cp = std.unicode.utf8Decode(text[i..]) catch {
                i += 1;
                continue;
            };
            const seq_len = std.unicode.utf8CodepointSequenceLength(cp) catch 1;
            const is_cjk = (cp >= 0x4E00 and cp <= 0x9FFF) or
                           (cp >= 0x3400 and cp <= 0x4DBF) or
                           (cp >= 0x2E80 and cp <= 0x2EFF) or
                           (cp >= 0x3000 and cp <= 0x303F) or
                           (cp >= 0xFF00 and cp <= 0xFFEF);
            const cjk_width: f32 = if (is_cjk) char_width * 2 else char_width;
            if (cp == '\t') {
                const tab_w = cjk_width * @as(f32, @floatFromInt(tab_size));
                try line.glyphs.append(.{
                    .codepoint = cp,
                    .cluster = @intCast(i),
                    .x_advance = tab_w,
                    .y_advance = 0,
                    .x_offset = 0,
                    .y_offset = 0,
                    .width = tab_w,
                    .height = char_height,
                    .is_cjk = false,
                });
                x += tab_w;
            } else {
                try line.glyphs.append(.{
                    .codepoint = cp,
                    .cluster = @intCast(i),
                    .x_advance = cjk_width,
                    .y_advance = 0,
                    .x_offset = 0,
                    .y_offset = 0,
                    .width = cjk_width,
                    .height = char_height,
                    .is_cjk = is_cjk,
                });
                x += cjk_width;
            }
            i += seq_len;
        }
        line.width = x;
        line.height = char_height;
        return line;
    }

    pub fn charWidth(self: *const TextShaper, cp: u21) f32 {
        const base = self.font_size * 0.6;
        if (cp >= 0x4E00 and cp <= 0x9FFF) return base * 2;
        if (cp >= 0x3400 and cp <= 0x4DBF) return base * 2;
        if (cp >= 0x2E80 and cp <= 0x2EFF) return base * 2;
        if (cp >= 0x3000 and cp <= 0x303F) return base * 2;
        if (cp >= 0xFF00 and cp <= 0xFFEF) return base * 2;
        if (cp == '\t') return base * 4;
        return base;
    }
};
