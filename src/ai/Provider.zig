const std = @import("std");

pub const ChatMessage = struct {
    role: enum { system, user, assistant },
    content: []const u8,
};

pub const ChatOptions = struct {
    temperature: f32 = 0.7,
    max_tokens: usize = 4096,
    stream: bool = true,
};

pub const ChatResponse = struct {
    content: []const u8,
    usage: ?struct {
        prompt_tokens: usize,
        completion_tokens: usize,
        total_tokens: usize,
    },
};

pub const AIProvider = struct {
    allocator: std.mem.Allocator,
    api_key: ?[]const u8,
    base_url: ?[]const u8,
    model: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator) AIProvider {
        return AIProvider{ .allocator = allocator, .api_key = null, .base_url = null, .model = null };
    }

    pub fn deinit(self: *AIProvider) void {
        if (self.api_key) |k| self.allocator.free(k);
        if (self.base_url) |u| self.allocator.free(u);
        if (self.model) |m| self.allocator.free(m);
    }

    pub fn chat(self: *const AIProvider, messages: []const ChatMessage, options: ChatOptions) !ChatResponse {
        _ = self; _ = messages; _ = options;
        return ChatResponse{ .content = "AI 响应", .usage = null };
    }

    pub fn streamChat(self: *const AIProvider, messages: []const ChatMessage, options: ChatOptions, callback: *const fn ([]const u8) void) !void {
        _ = self; _ = messages; _ = options; _ = callback;
    }

    pub fn complete(self: *const AIProvider, prompt: []const u8, options: ChatOptions) !ChatResponse {
        return self.chat(&.{.{ .role = .user, .content = prompt }}, options);
    }
};
