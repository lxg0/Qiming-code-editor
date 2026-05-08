//! Metal GPU renderer for macOS.
//! All GPU work is dispatched through the Objective-C bridge.

const std = @import("std");
const Bridge = @import("Bridge.zig");
const Color  = @import("../../rendering/Theme.zig").Color;
const Theme  = @import("../../rendering/Theme.zig").Theme;

/// Font size clamping
pub const FONT_SIZE_MIN: f32 = 8.0;
pub const FONT_SIZE_MAX: f32 = 72.0;
pub const FONT_SIZE_DEFAULT: f32 = 14.0;

pub const MetalRenderer = struct {
    allocator:    std.mem.Allocator,
    width:        u32,         // logical width (CSS pixels)
    height:       u32,         // logical height (CSS pixels)
    scale:        f32,         // backing scale factor (2.0 on Retina)
    pixel_width:  u32,         // actual pixel width = width * scale
    pixel_height: u32,         // actual pixel height = height * scale

    device:       ?*anyopaque,
    metal_layer:  ?*anyopaque,
    theme:        Theme,
    frame_count:  u64,
    initialized:  bool,
    font_size:    f32,
    glyph_scale:  f32,         // = scale, used for crisp glyph rendering

    pub fn init(allocator: std.mem.Allocator) MetalRenderer {
        return .{
            .allocator     = allocator,
            .width         = 1200,
            .height        = 800,
            .scale         = 2.0,
            .pixel_width   = 2400,
            .pixel_height  = 1600,
            .device        = null,
            .metal_layer   = null,
            .theme         = Theme.default(),
            .frame_count   = 0,
            .initialized   = false,
            .font_size     = FONT_SIZE_DEFAULT,
            .glyph_scale   = 2.0,
        };
    }

    pub fn deinit(self: *MetalRenderer) void {
        _ = self;
    }

    // ── Setup ─────────────────────────────────────────────────────────────────

    pub fn setup(self: *MetalRenderer, window_handle: ?*anyopaque) !void {
        const ok = Bridge.qiming_metal_setup(window_handle);
        if (ok == 0) return error.MetalSetupFailed;
        self.initialized = true;
        std.debug.print("[Metal] 渲染管线初始化完成 (scale={d:.1})\n", .{self.scale});
    }

    pub fn resize(self: *MetalRenderer, width: u32, height: u32) void {
        self.width        = width;
        self.height       = height;
        self.pixel_width  = @intFromFloat(@as(f32, @floatFromInt(width)) * self.scale);
        self.pixel_height = @intFromFloat(@as(f32, @floatFromInt(height)) * self.scale);
        if (self.initialized) {
            Bridge.qiming_metal_set_viewport(
                @floatFromInt(self.pixel_width),
                @floatFromInt(self.pixel_height),
            );
        }
    }

    pub fn setTheme(self: *MetalRenderer, theme: Theme) void {
        self.theme = theme;
    }

    // ── Per-frame API ─────────────────────────────────────────────────────────

    pub fn beginFrame(self: *MetalRenderer) bool {
        if (!self.initialized) return false;
        self.frame_count += 1;
        const bg = self.theme.background;
        const ok = Bridge.qiming_metal_begin_frame(
            @as(f32, @floatFromInt(bg.r)) / 255.0,
            @as(f32, @floatFromInt(bg.g)) / 255.0,
            @as(f32, @floatFromInt(bg.b)) / 255.0,
        );
        return ok != 0;
    }

    pub fn endFrame(self: *MetalRenderer) void {
        if (!self.initialized) return;
        Bridge.qiming_metal_end_frame();
    }

    // ── Draw primitives ───────────────────────────────────────────────────────

    pub fn drawRect(self: *MetalRenderer, x: f32, y: f32, w: f32, h: f32, color: Color) void {
        if (!self.initialized) return;
        Bridge.qiming_metal_draw_rect(
            x * self.scale, y * self.scale, w * self.scale, h * self.scale,
            @as(f32, @floatFromInt(color.r)) / 255.0,
            @as(f32, @floatFromInt(color.g)) / 255.0,
            @as(f32, @floatFromInt(color.b)) / 255.0,
            @as(f32, @floatFromInt(color.a)) / 255.0,
        );
    }

    pub fn drawText(self: *MetalRenderer, text: [:0]const u8, x: f32, y: f32, color: Color, size: f32) void {
        if (!self.initialized) return;
        // Glyph pixel size = logical size * glyph_scale (font is rasterized at Retina resolution)
        const pixel_size = size * self.glyph_scale;
        Bridge.qiming_metal_draw_text(
            text.ptr,
            x * self.scale, y * self.scale,
            @as(f32, @floatFromInt(color.r)) / 255.0,
            @as(f32, @floatFromInt(color.g)) / 255.0,
            @as(f32, @floatFromInt(color.b)) / 255.0,
            @as(f32, @floatFromInt(color.a)) / 255.0,
            pixel_size,
            null, // default Menlo monospace
        );
    }

    pub fn drawTextDefault(self: *MetalRenderer, text: [:0]const u8, x: f32, y: f32, color: Color) void {
        self.drawText(text, x, y, color, self.font_size);
    }

    // ── Event polling ─────────────────────────────────────────────────────────

    pub fn pollEvent(self: *MetalRenderer) ?Bridge.Event {
        _ = self;
        var ev: Bridge.Event = undefined;
        if (Bridge.qiming_poll_event_zig(@ptrCast(&ev)) != 0) return ev;
        return null;
    }
};
