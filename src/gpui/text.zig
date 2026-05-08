const std = @import("std");
const Rect = @import("Rect");

pub const FontMetrics = struct {
    ascent: f32,
    descent: f32,
    line_gap: f32,
};

pub const Glyph = struct {
    codepoint: u32,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

pub const TextLayout = struct {
    allocator: std.mem.Allocator,
    text: []const u8,
    font_size: f32,
    font_weight: u16,
    width: f32,
    glyphs: std.array_list.Managed(Glyph),

    pub fn init(allocator: std.mem.Allocator) TextLayout {
        return TextLayout{
            .allocator = allocator,
            .text = &.{},
            .font_size = 14,
            .font_weight = 400,
            .width = undefined,
            .glyphs = std.array_list.Managed(Glyph).init(allocator),
        };
    }

    pub fn deinit(self: *TextLayout) void {
        self.glyphs.deinit();
    }

    pub fn setText(self: *TextLayout, text: []const u8, width: f32) !void {
        self.text = text;
        self.width = width;
        self.glyphs.clearRetainingCapacity();
        try self.layout();
    }

    fn layout(self: *TextLayout) !void {
        var x: f32 = 0;
        var y: f32 = 0;
        const char_width = self.font_size * 0.6;

        for (self.text) |c| {
            if (c == '\n') {
                x = 0;
                y += self.font_size * 1.2;
                continue;
            }

            if (x + char_width > self.width and x > 0) {
                x = 0;
                y += self.font_size * 1.2;
            }

            try self.glyphs.append(Glyph{
                .codepoint = @as(u32, c),
                .x = x,
                .y = y,
                .width = char_width,
                .height = self.font_size,
            });

            x += char_width;
        }
    }

    pub fn hitTest(self: *TextLayout, point: Rect.Point) ?usize {
        for (self.glyphs.items, 0..) |glyph, i| {
            const rect = Rect.new(glyph.x, glyph.y, glyph.width, glyph.height);
            if (rect.containsPoint(point)) {
                return i;
            }
        }
        return null;
    }
};

pub const FontId = u32;

pub const FontManager = struct {
    allocator: std.mem.Allocator,
    fonts: std.StringHashMap(FontId),

    pub fn init(allocator: std.mem.Allocator) FontManager {
        return FontManager{
            .allocator = allocator,
            .fonts = std.StringHashMap(FontId).init(allocator),
        };
    }

    pub fn deinit(self: *FontManager) void {
        self.fonts.deinit();
    }

    pub fn getFont(self: *FontManager, family: []const u8, weight: u16) FontId {
        const key = std.fmt.allocPrint(self.allocator, "{s}:{d}", .{family, weight}) catch return 0;
        defer self.allocator.free(key);

        if (self.fonts.get(key)) |id| {
            return id;
        }

        const new_id: FontId = @intCast(self.fonts.count() + 1);
        self.fonts.put(key, new_id) catch return 0;
        return new_id;
    }
};
