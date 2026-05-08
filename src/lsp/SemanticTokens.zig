const std = @import("std");

pub const SemanticToken = struct {
    line: usize,
    start_col: usize,
    length: usize,
    token_type: usize,
    token_modifiers: usize,
};

pub const SemanticTokensProvider = struct {
    allocator: std.mem.Allocator,
    tokens: std.array_list.Managed(SemanticToken),

    pub fn init(allocator: std.mem.Allocator) SemanticTokensProvider {
        return SemanticTokensProvider{ .allocator = allocator, .tokens = std.array_list.Managed(SemanticToken).init(allocator) };
    }

    pub fn deinit(self: *SemanticTokensProvider) void {
        self.tokens.deinit();
    }

    pub fn request(self: *SemanticTokensProvider, uri: []const u8) !void {
        _ = self; _ = uri;
    }
};
