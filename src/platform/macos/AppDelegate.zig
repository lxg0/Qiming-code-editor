//! NSApplication delegate for macOS GUI
//! Handles application lifecycle events

const std = @import("std");
const Log = @import("../../util/Log.zig").Logger;

pub const AppDelegate = struct {
    allocator: std.mem.Allocator,
    log: *Log,
    should_terminate: bool,

    pub fn init(allocator: std.mem.Allocator, log: *Log) AppDelegate {
        return .{
            .allocator = allocator,
            .log = log,
            .should_terminate = false,
        };
    }

    pub fn deinit(self: *AppDelegate) void {
        _ = self;
    }

    /// Called when application finishes launching
    pub fn onLaunch(self: *AppDelegate, notification: ?*anyopaque) void {
        _ = notification;
        self.log.info("[GUI] 应用程序启动完成", .{});
    }

    /// Called when application is about to terminate
    pub fn onTerminate(self: *AppDelegate, notification: ?*anyopaque) void {
        _ = notification;
        self.should_terminate = true;
        self.log.info("[GUI] 应用程序即将退出", .{});
    }

    /// Called when last window is closed
    pub fn onLastWindowClosed(self: *AppDelegate) bool {
        self.log.info("[GUI] 最后一个窗口已关闭", .{});
        return true; // Return true = terminate app
    }
};
