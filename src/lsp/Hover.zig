const std = @import("std");
const Protocol = @import("Protocol.zig");

pub const HoverProvider = struct {
    allocator: std.mem.Allocator,
    result: ?Protocol.Hover,

    pub fn init(allocator: std.mem.Allocator) HoverProvider {
        return HoverProvider{ .allocator = allocator, .result = null };
    }

    pub fn deinit(self: *HoverProvider) void {
        _ = self;
    }

    pub fn request(self: *HoverProvider, uri: []const u8, line: usize, col: usize) !void {
        _ = self; _ = uri; _ = line; _ = col;
    }

    pub fn handleResponse(self: *HoverProvider, json: []const u8) !void {
        _ = self; _ = json;
    }
};
