//! Metal GPU renderer for macOS.
//! All GPU work is dispatched through the Objective-C bridge.

const std = @import("std");
const Bridge = @import("Bridge.zig");
const Color  = @import("../../rendering/Theme.zig").Color;
const Theme  = @import("../../rendering/Theme.zig").Theme;

pub const MetalRenderer = struct {
    allocator:    std.mem.Allocator,
    width:        u32,
    height:       u32,
    scale:        f32,
    device:       ?*anyopaque,
    metal_layer:  ?*anyopaque,
    theme:        Theme,
    frame_count:  u64,
    initialized:  bool,
    font_name:    ?[:0]const u8,   // null → Menlo (default monospace)
    font_size:    f32,

    pub fn init(allocator: std.mem.Allocator) MetalRenderer {
        return .{
            .allocator   = allocator,
            .width       = 800,
            .height      = 600,
            .scale       = 2.0,
            .device      = null,
            .metal_layer = null,
            .theme       = Theme.default(),
            .frame_count = 0,
            .initialized = false,
            .font_name   = null,
            .font_size   = 14.0,
        };
    }

    pub fn deinit(self: *MetalRenderer) void {
        _ = self;
    }

    // ── Setup ─────────────────────────────────────────────────────────────────

    /// Call once with the window handle after the window is created.
    pub fn setup(self: *MetalRenderer, window_handle: ?*anyopaque) !void {
        const ok = Bridge.qiming_metal_setup(window_handle);
        if (ok == 0) return error.MetalSetupFailed;
        self.initialized = true;
        std.debug.print("[Metal] 渲染管线初始化完成\n", .{});
    }

    pub fn resize(self: *MetalRenderer, width: u32, height: u32) void {
        self.width  = width;
        self.height = height;
        if (self.initialized) {
            Bridge.qiming_metal_set_viewport(
                @floatFromInt(width),
                @floatFromInt(height),
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
        Bridge.qiming_metal_draw_rect(x, y, w, h,
            @as(f32, @floatFromInt(color.r)) / 255.0,
            @as(f32, @floatFromInt(color.g)) / 255.0,
            @as(f32, @floatFromInt(color.b)) / 255.0,
            @as(f32, @floatFromInt(color.a)) / 255.0,
        );
    }

    pub fn drawText(self: *MetalRenderer, text: [:0]const u8, x: f32, y: f32, color: Color, size: f32) void {
        if (!self.initialized) return;
        const fname: ?[*:0]const u8 = if (self.font_name) |n| n.ptr else null;
        Bridge.qiming_metal_draw_text(
            text.ptr, x, y,
            @as(f32, @floatFromInt(color.r)) / 255.0,
            @as(f32, @floatFromInt(color.g)) / 255.0,
            @as(f32, @floatFromInt(color.b)) / 255.0,
            @as(f32, @floatFromInt(color.a)) / 255.0,
            size,
            fname,
        );
    }

    /// Convenience: draw with the renderer's default font size.
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
