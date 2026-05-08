const std = @import("std");
const Provider = @import("Provider.zig");

pub const OpenAIProvider = struct {
    allocator: std.mem.Allocator,
    api_key: []const u8,
    model: []const u8,

    pub fn init(allocator: std.mem.Allocator) OpenAIProvider {
        return OpenAIProvider{ .allocator = allocator, .api_key = "", .model = "gpt-4o" };
    }

    pub fn deinit(self: *OpenAIProvider) void {
        self.allocator.free(self.api_key);
    }

    pub fn setApiKey(self: *OpenAIProvider, key: []const u8) !void {
        self.allocator.free(self.api_key);
        self.api_key = try self.allocator.dupe(u8, key);
    }

    pub fn chat(self: *const OpenAIProvider, messages: []const Provider.ChatMessage, options: Provider.ChatOptions) !Provider.ChatResponse {
        _ = messages; _ = options;
        if (self.api_key.len == 0) return error.ApiKeyNotSet;
        return Provider.ChatResponse{ .content = "GPT 响应", .usage = null };
    }
};
