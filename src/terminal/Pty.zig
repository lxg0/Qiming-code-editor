const std = @import("std");

pub const Pty = struct {
    allocator: std.mem.Allocator,
    pid: std.process.Child,
    master_fd: std.fs.File,
    slave_name: []const u8,

    pub fn init(allocator: std.mem.Allocator, cols: usize, rows: usize) !Pty {
        _ = allocator; _ = cols; _ = rows;
        return error.UnsupportedOnThisPlatform;
    }

    pub fn deinit(self: *Pty) void {
        _ = self;
    }

    pub fn write(self: *Pty, data: []const u8) !void {
        _ = self; _ = data;
    }

    pub fn read(self: *Pty) ![]u8 {
        _ = self;
        return &[_]u8{};
    }

    pub fn resize(self: *Pty, cols: usize, rows: usize) !void {
        _ = self; _ = cols; _ = rows;
    }
};
