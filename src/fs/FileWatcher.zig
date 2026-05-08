const std = @import("std");

pub const FileChange = struct {
    path: []const u8,
    kind: enum { modified, created, deleted },
};

pub const FileWatcher = struct {
    allocator: std.mem.Allocator,
    watching: bool,
    callback: ?*const fn (FileChange) void,

    pub fn init(allocator: std.mem.Allocator) FileWatcher {
        return FileWatcher{ .allocator = allocator, .watching = false, .callback = null };
    }

    pub fn deinit(self: *FileWatcher) void {
        self.stop() catch {};
    }

    pub fn start(self: *FileWatcher, path: []const u8, cb: *const fn (FileChange) void) !void {
        _ = path;
        self.callback = cb;
        self.watching = true;
    }

    pub fn stop(self: *FileWatcher) !void {
        self.watching = false;
    }
};
