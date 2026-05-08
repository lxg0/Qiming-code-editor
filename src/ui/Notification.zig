const std = @import("std");

pub const NotificationLevel = enum {
    info,
    warn,
    err,
    success,
};

pub const Notification = struct {
    id: u64,
    message: []const u8,
    level: NotificationLevel,
    timestamp: u64,
    duration_ms: u64,
};

pub const NotificationManager = struct {
    allocator: std.mem.Allocator,
    notifications: std.array_list.Managed(Notification),

    pub fn init(allocator: std.mem.Allocator) NotificationManager {
        return NotificationManager{
            .allocator = allocator,
            .notifications = std.array_list.Managed(Notification).init(allocator),
        };
    }

    pub fn deinit(self: *NotificationManager) void {
        self.notifications.deinit();
    }

    pub fn notify(self: *NotificationManager, message: []const u8, level: NotificationLevel) void {
        self.notifications.append(.{
            .id = @intCast(@import("../util/Async.zig").timestampMs()),
            .message = message,
            .level = level,
            .timestamp = @intCast(@import("../util/Async.zig").timestampMs()),
            .duration_ms = 3000,
        }) catch {};
    }

    pub fn info(self: *NotificationManager, msg: []const u8) void { self.notify(msg, .info); }
    pub fn warn(self: *NotificationManager, msg: []const u8) void { self.notify(msg, .warn); }
    pub fn err(self: *NotificationManager, msg: []const u8) void { self.notify(msg, .err); }
    pub fn success(self: *NotificationManager, msg: []const u8) void { self.notify(msg, .success); }
};
