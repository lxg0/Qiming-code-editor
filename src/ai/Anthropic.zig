const std = @import("std");
const Provider = @import("Provider.zig");
const ChatMessage = Provider.ChatMessage;
const ChatOptions = Provider.ChatOptions;
const ChatResponse = Provider.ChatResponse;

pub const AnthropicProvider = struct {
    allocator: std.mem.Allocator,
    api_key: []const u8,
    model: []const u8,

    pub fn init(allocator: std.mem.Allocator) AnthropicProvider {
        return AnthropicProvider{ .allocator = allocator, .api_key = "", .model = "claude-sonnet-4-20250514" };
    }

    pub fn deinit(self: *AnthropicProvider) void {
        _ = self;
    }

    pub fn setApiKey(self: *AnthropicProvider, key: []const u8) !void {
        self.allocator.free(self.api_key);
        self.api_key = try self.allocator.dupe(u8, key);
    }

    pub fn chat(self: *const AnthropicProvider, messages: []const ChatMessage, options: ChatOptions) !ChatResponse {
        _ = messages; _ = options;
        if (self.api_key.len == 0) return error.ApiKeyNotSet;
        return ChatResponse{ .content = "Claude 响应", .usage = null };
    }

    pub fn streamChat(self: *const AnthropicProvider, messages: []const ChatMessage, options: ChatOptions, callback: *const fn ([]const u8) void) !void {
        _ = self; _ = messages; _ = options; _ = callback;
    }
};
