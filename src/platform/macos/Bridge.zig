//! Zig declarations for the Objective-C macOS bridge.

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
