const std = @import("std");

pub const TuiIo = struct {
    io: std.Io,
    allocator: std.mem.Allocator,

    pub fn init(init: std.process.Init) TuiIo {
        return TuiIo{
            .io = init.io,
            .allocator = init.allocator,
        };
    }

    pub fn print(self: *TuiIo, comptime format: []const u8, args: anytype) !void {
        try std.Io.File.stdout().writer(self.io).print(format, args);
    }

    pub fn write(self: *TuiIo, s: []const u8) !void {
        try std.Io.File.stdout().writeStreamingAll(self.io, s);
    }

    pub fn readLine(self: *TuiIo, buf: *std.array_list.Managed(u8)) !?[]const u8 {
        const stdin = std.Io.File.stdin();
        var reader = stdin.reader(self.io);
        return try reader.readLine(buf);
    }

    pub fn readBytes(self: *TuiIo, buffer: []u8) !usize {
        const stdin = std.Io.File.stdin();
        var reader = stdin.reader(self.io);
        return try reader.read(buffer);
    }
};
