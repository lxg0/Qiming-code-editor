const std = @import("std");
const Protocol = @import("Protocol.zig");

pub const GotoProvider = struct {
    allocator: std.mem.Allocator,
    definition: ?Protocol.Location,
    references: std.array_list.Managed(Protocol.Location),

    pub fn init(allocator: std.mem.Allocator) GotoProvider {
        return GotoProvider{
            .allocator = allocator,
            .definition = null,
            .references = std.array_list.Managed(Protocol.Location).init(allocator),
        };
    }

    pub fn deinit(self: *GotoProvider) void {
        self.references.deinit();
    }

    pub fn gotoDefinition(self: *GotoProvider, uri: []const u8, line: usize, col: usize) !void {
        _ = self; _ = uri; _ = line; _ = col;
    }

    pub fn findReferences(self: *GotoProvider, uri: []const u8, line: usize, col: usize) !void {
        _ = self; _ = uri; _ = line; _ = col;
    }
};
