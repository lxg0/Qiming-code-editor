const std = @import("std");
const Renderer = @import("../Renderer.zig").Renderer;
const Theme = @import("../Theme.zig").Theme;
const Color = @import("../Theme.zig").Color;

pub const GuiRenderer = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    scale: f32,
    theme: Theme,

    pub fn init(allocator: std.mem.Allocator) GuiRenderer {
        return GuiRenderer{
            .allocator = allocator,
            .width = 800,
            .height = 600,
            .scale = 1.0,
            .theme = Theme.default(),
        };
    }

    pub fn deinit(self: *GuiRenderer) void {
        _ = self;
    }

    pub fn setSize(self: *GuiRenderer, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
    }

    pub fn setScale(self: *GuiRenderer, scale: f32) void {
        self.scale = scale;
    }

    pub fn setTheme(self: *GuiRenderer, theme: Theme) void {
        self.theme = theme;
    }

    pub fn clear(self: *GuiRenderer, color: Color) void {
        _ = color;
    }

    pub fn drawRect(self: *GuiRenderer, x: f32, y: f32, w: f32, h: f32, color: Color, radius: f32) void {
        _ = self; _ = x; _ = y; _ = w; _ = h; _ = color; _ = radius;
    }

    pub fn drawText(self: *GuiRenderer, text: []const u8, x: f32, y: f32, color: Color, size: f32) void {
        _ = self; _ = text; _ = x; _ = y; _ = color; _ = size;
    }

    pub fn present(self: *GuiRenderer) !void {
        _ = self;
    }
};
