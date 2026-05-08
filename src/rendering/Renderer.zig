const std = @import("std");
const Theme = @import("Theme.zig").Theme;

pub const RenderMode = enum {
    gui,
    tui,
    headless,
};

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    mode: RenderMode,
    width: u32,
    height: u32,
    scale: f32,
    theme: Theme,

    pub fn init(allocator: std.mem.Allocator, mode: RenderMode) Renderer {
        return Renderer{
            .allocator = allocator,
            .mode = mode,
            .width = 800,
            .height = 600,
            .scale = 1.0,
            .theme = Theme.default(),
        };
    }

    pub fn deinit(self: *Renderer) void {
        _ = self;
    }

    pub fn setSize(self: *Renderer, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
    }

    pub fn setScale(self: *Renderer, scale: f32) void {
        self.scale = scale;
    }

    pub fn setTheme(self: *Renderer, theme: Theme) void {
        self.theme = theme;
    }

    pub fn beginFrame(self: *Renderer) void {
        _ = self;
    }

    pub fn endFrame(self: *Renderer) !void {
        _ = self;
    }

    pub fn present(self: *Renderer) !void {
        _ = self;
    }
};
