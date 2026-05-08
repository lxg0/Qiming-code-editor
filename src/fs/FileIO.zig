const std = @import("std");
const Buffer = @import("../buffer/Buffer.zig").Buffer;

pub const FileIO = struct {
    allocator: std.mem.Allocator,
    current_file: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator) FileIO {
        return FileIO{ .allocator = allocator, .current_file = null };
    }

    pub fn deinit(self: *FileIO) void {
        if (self.current_file) |f| self.allocator.free(f);
    }

    pub fn open(self: *FileIO, path: []const u8) ![]u8 {
        var threaded_io = std.Io.Threaded.init(self.allocator, .{});
        defer threaded_io.deinit();
        const io: std.Io = threaded_io.io();
        const content = try std.Io.Dir.readFileAlloc(.cwd(), io, path, self.allocator, std.Io.Limit.limited(10 * 1024 * 1024));
        if (self.current_file) |f| self.allocator.free(f);
        self.current_file = try self.allocator.dupe(u8, path);
        return content;
    }

    pub fn save(self: *FileIO, path: []const u8, content: []const u8) !void {
        var threaded_io = std.Io.Threaded.init(self.allocator, .{});
        defer threaded_io.deinit();
        const io: std.Io = threaded_io.io();
        std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = path, .data = content }) catch {};
        if (self.current_file) |f| self.allocator.free(f);
        self.current_file = try self.allocator.dupe(u8, path);
    }

    pub fn getCurrentPath(self: *const FileIO) ?[]const u8 {
        return self.current_file;
    }
};
