const std = @import("std");
const Provider = @import("Provider.zig");

pub const OllamaProvider = struct {
    allocator: std.mem.Allocator,
    base_url: []const u8,
    model: []const u8,

    pub fn init(allocator: std.mem.Allocator) OllamaProvider {
        return OllamaProvider{ .allocator = allocator, .base_url = "http://localhost:11434", .model = "codellama" };
    }

    pub fn deinit(self: *OllamaProvider) void {
        _ = self;
    }

    pub fn chat(_: *const OllamaProvider, _: []const Provider.ChatMessage, _: Provider.ChatOptions) !Provider.ChatResponse {
        return Provider.ChatResponse{ .content = "Ollama 响应", .usage = null };
    }
};
