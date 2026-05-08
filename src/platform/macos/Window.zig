//! Native macOS window using NSWindow + NSView + CAMetalLayer
//! Provides a GPU-accelerated rendering surface for the editor

const std = @import("std");
const MetalRenderer = @import("MetalRenderer.zig").MetalRenderer;
const Bridge = @import("Bridge.zig");
const Theme = @import("../../rendering/Theme.zig").Theme;
const Color = @import("../../rendering/Theme.zig").Color;

pub const WindowConfig = struct {
    title: []const u8 = "Qiming Editor - 启明编辑器",
    width: u32 = 1200,
    height: u32 = 800,
    min_width: u32 = 400,
    min_height: u32 = 300,
    resizable: bool = true,
    transparent_titlebar: bool = false,
};

pub const NativeWindow = struct {
    allocator: std.mem.Allocator,
    config: WindowConfig,
    width: u32,
    height: u32,
    scale: f32,          // backingScaleFactor (2.0 on Retina)
    scale_factor: f32,   // display's native pixel ratio

    // Native window handles (opaque until we link ObjC)
    native_handle: ?*anyopaque,
    ns_window: ?*anyopaque,
    ns_view: ?*anyopaque,
    metal_layer: ?*anyopaque,

    // Renderer
    renderer: MetalRenderer,

    // Window state
    visible: bool,
    focused: bool,
    miniaturized: bool,
    fullscreen: bool,

    pub fn init(allocator: std.mem.Allocator, config: WindowConfig) !NativeWindow {
        var window = NativeWindow{
            .allocator = allocator,
            .config = config,
            .width = config.width,
            .height = config.height,
            .scale = 2.0,
            .scale_factor = 2.0,
            .native_handle = null,
            .ns_window = null,
            .ns_view = null,
            .metal_layer = null,
            .renderer = MetalRenderer.init(allocator),
            .visible = false,
            .focused = false,
            .miniaturized = false,
            .fullscreen = false,
        };

        window.renderer.resize(config.width, config.height);
        window.renderer.scale = window.scale;

        return window;
    }

    pub fn deinit(self: *NativeWindow) void {
        self.renderer.deinit();
        self.close();
    }

    /// Open the window (creates NSWindow when ObjC is linked)
    pub fn open(self: *NativeWindow) !void {
        std.debug.print("[Window] 打开窗口: {s} ({d}x{d})\n", .{
            self.config.title,
            self.config.width,
            self.config.height,
        });

        const title_z = try self.allocator.dupeZ(u8, self.config.title);
        defer self.allocator.free(title_z);

        Bridge.qiming_macos_init_app();
        const handle = Bridge.qiming_macos_create_window(title_z.ptr, @intCast(self.config.width), @intCast(self.config.height)) orelse return error.WindowCreationFailed;
        Bridge.qiming_macos_show_window(handle);

        self.native_handle = handle;
        self.metal_layer = Bridge.qiming_macos_get_metal_layer(handle);
        self.renderer.device = Bridge.qiming_macos_get_metal_device(handle);
        self.renderer.metal_layer = self.metal_layer;
        self.scale_factor = @as(f32, @floatCast(Bridge.qiming_macos_get_backing_scale_factor()));
        self.scale = self.scale_factor;
        self.renderer.scale = self.scale;

        // Initialize Metal pipeline (shaders, command queue, glyph atlas)
        try self.renderer.setup(handle);

        self.visible = true;
        self.focused = true;
    }

    /// Close and destroy the window
    pub fn close(self: *NativeWindow) void {
        if (self.native_handle) |handle| {
            Bridge.qiming_macos_destroy_window(handle);
            self.native_handle = null;
        }
        self.visible = false;
        self.focused = false;
        std.debug.print("[Window] 窗口已关闭\n", .{});
    }

    /// Begin frame rendering. Returns false if no drawable is available.
    pub fn beginFrame(self: *NativeWindow) bool {
        return self.renderer.beginFrame();
    }

    /// End frame and present to screen.
    pub fn endFrame(self: *NativeWindow) void {
        self.renderer.endFrame();
    }

    /// Request a redraw of the window content
    pub fn requestRedraw(self: *NativeWindow) void {
        if (self.native_handle) |_| {
            _ = Bridge.qiming_macos_pump_events();
        }
    }

    /// Handle resize event
    pub fn handleResize(self: *NativeWindow, width: u32, height: u32) void {
        if (width == self.width and height == self.height and false) return;
        self.width = width;
        self.height = height;
        // Apply the actual backing scale to the metal layer drawable size
        self.renderer.resize(width, height);
        if (self.native_handle) |handle| {
            Bridge.qiming_macos_set_drawable_size(handle, @intCast(width), @intCast(height), self.scale_factor);
        }
    }

    /// Handle focus gained
    pub fn handleFocusGained(self: *NativeWindow) void {
        self.focused = true;
    }

    /// Handle focus lost
    pub fn handleFocusLost(self: *NativeWindow) void {
        self.focused = false;
    }

    /// Show a native dialog
    pub fn showMessage(self: *NativeWindow, title: []const u8, message: []const u8, kind: enum { info, warn, err }) void {
        _ = self;
        _ = kind;
        std.debug.print("[Window] {s}: {s}\n", .{ title, message });
    }
};
