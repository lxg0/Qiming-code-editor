//! Platform abstraction layer
//! Selects the appropriate platform backend at compile time

const builtin = @import("builtin");

pub const macos = if (builtin.os.tag == .macos) @import("macos/mod.zig") else struct {};

pub fn isMacOS() bool {
    return builtin.os.tag == .macos;
}
