const std = @import("std");

pub const TreeSitterNode = struct {
    kind: []const u8,
    start_byte: usize,
    end_byte: usize,
    start_row: usize,
    end_row: usize,
    children: []TreeSitterNode,
};

pub const TreeSitter = struct {
    allocator: std.mem.Allocator,
    initialized: bool,

    pub fn init(allocator: std.mem.Allocator) TreeSitter {
        return TreeSitter{ .allocator = allocator, .initialized = false };
    }

    pub fn deinit(self: *TreeSitter) void {
        _ = self;
    }

    pub fn initLang(self: *TreeSitter, lang: []const u8) !void {
        _ = lang;
        self.initialized = true;
    }

    pub fn parse(self: *TreeSitter, source: []const u8) ![]TreeSitterNode {
        _ = source;
        return &[_]TreeSitterNode{};
    }

    pub fn isInitialized(self: *const TreeSitter) bool {
        return self.initialized;
    }
};
