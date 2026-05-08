const std = @import("std");
const Protocol = @import("Protocol.zig");

pub const CompletionProvider = struct {
    allocator: std.mem.Allocator,
    items: std.array_list.Managed(Protocol.CompletionItem),

    pub fn init(allocator: std.mem.Allocator) CompletionProvider {
        return CompletionProvider{ .allocator = allocator, .items = std.array_list.Managed(Protocol.CompletionItem).init(allocator) };
    }

    pub fn deinit(self: *CompletionProvider) void {
        self.items.deinit();
    }

    pub fn request(self: *CompletionProvider, uri: []const u8, line: usize, col: usize) !void {
        _ = self; _ = uri; _ = line; _ = col;
    }

    pub fn handleResponse(self: *CompletionProvider, json: []const u8) !void {
        _ = json;
    }
};
