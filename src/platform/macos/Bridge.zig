//! Zig declarations for the Objective-C macOS bridge.

// ── Window lifecycle ──────────────────────────────────────────────────────────
pub extern fn qiming_macos_init_app() void;
pub extern fn qiming_macos_create_window(title: [*:0]const u8, width: c_int, height: c_int) ?*anyopaque;
pub extern fn qiming_macos_show_window(handle: ?*anyopaque) void;
pub extern fn qiming_macos_close_window(handle: ?*anyopaque) void;
pub extern fn qiming_macos_destroy_window(handle: ?*anyopaque) void;
pub extern fn qiming_macos_window_should_close(handle: ?*anyopaque) c_int;
pub extern fn qiming_macos_set_drawable_size(handle: ?*anyopaque, width: c_int, height: c_int, scale: f64) void;
pub extern fn qiming_macos_get_metal_layer(handle: ?*anyopaque) ?*anyopaque;
pub extern fn qiming_macos_get_metal_device(handle: ?*anyopaque) ?*anyopaque;
pub extern fn qiming_macos_pump_events() c_int;

// ── Metal pipeline setup ───────────────────────────────────────────────────────
/// Call once after creating the window. Returns 1 on success.
pub extern fn qiming_metal_setup(window_handle: ?*anyopaque) c_int;
/// Update viewport when window is resized.
pub extern fn qiming_metal_set_viewport(w: f32, h: f32) void;

// ── Per-frame rendering ────────────────────────────────────────────────────────
/// Begin frame, clear with (r,g,b). Returns 1 if drawable is available.
pub extern fn qiming_metal_begin_frame(r: f32, g: f32, b: f32) c_int;
/// End frame and present to screen.
pub extern fn qiming_metal_end_frame() void;
/// Draw a filled rectangle.
pub extern fn qiming_metal_draw_rect(x: f32, y: f32, w: f32, h: f32,
                                      r: f32, g: f32, b: f32, a: f32) void;
/// Draw UTF-8 text. font_name may be null (defaults to Menlo).
pub extern fn qiming_metal_draw_text(utf8_text: [*:0]const u8,
                                      x: f32, y: f32,
                                      r: f32, g: f32, b: f32, a: f32,
                                      font_size: f32,
                                      font_name: ?[*:0]const u8) void;

// ── Event polling ─────────────────────────────────────────────────────────────
/// Returns 1 if an event was written into `out` (raw C struct pointer).
pub extern fn qiming_poll_event_zig(out: ?*anyopaque) c_int;
/// Returns sizeof(QimingEvent) for sanity checks.
pub extern fn qiming_event_size() c_int;

// ── Event types (mirror of C #define) ────────────────────────────────────────
pub const EVENT_NONE       = 0;
pub const EVENT_KEY        = 1;
pub const EVENT_MOUSE_DOWN = 2;
pub const EVENT_MOUSE_UP   = 3;
pub const EVENT_MOUSE_MOVE = 4;
pub const EVENT_SCROLL     = 5;
pub const EVENT_RESIZE     = 6;
pub const EVENT_CLOSE      = 7;
pub const EVENT_TEXT       = 8;

/// Mirror of `QimingEvent` C struct.
pub const Event = extern struct {
    type:       c_int,
    keycode:    u16,
    modifiers:  u32,
    text:       [8]u8,
    mouse_x:    f32,
    mouse_y:    f32,
    scroll_dx:  f32,
    scroll_dy:  f32,
    width:      c_int,
    height:     c_int,
};
