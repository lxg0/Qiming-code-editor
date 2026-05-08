const std = @import("std");

pub const Level = enum(u3) {
    debug = 0,
    info = 1,
    warn = 2,
    err = 3,
    fatal = 4,
};

pub const Logger = struct {
    allocator: std.mem.Allocator,
    level: Level,

    pub fn init(allocator: std.mem.Allocator) Logger {
        return Logger{ .allocator = allocator, .level = .info };
    }

    pub fn deinit(self: *Logger) void {
        _ = self;
    }

    pub fn setLevel(self: *Logger, level: Level) void {
        self.level = level;
    }

    pub fn log(self: *Logger, level: Level, comptime fmt: []const u8, args: anytype) void {
        if (@intFromEnum(level) < @intFromEnum(self.level)) return;
        const prefix: u8 = switch (level) {
            .debug => 0,
            .info => 1,
            .warn => 2,
            .err => 3,
            .fatal => 4,
        };
        const prefixes = [_][]const u8{ "[DEBUG]", "[INFO]", "[WARN]", "[ERROR]", "[FATAL]" };
        const tag = prefixes[prefix];
        const formatted = std.fmt.allocPrint(self.allocator, fmt, args) catch {
            std.debug.print("Log allocation failed\n", .{});
            return;
        };
        defer self.allocator.free(formatted);
        const full = std.fmt.allocPrint(self.allocator, "{s} {s}\n", .{ tag, formatted }) catch {
            std.debug.print("Log allocation failed\n", .{});
            return;
        };
        defer self.allocator.free(full);
        std.debug.print("{s}", .{full});
    }

    pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.debug, fmt, args);
    }
    pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.info, fmt, args);
    }
    pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.warn, fmt, args);
    }
    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.err, fmt, args);
    }
    pub fn fatal(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.fatal, fmt, args);
    }
};
