const std = @import("std");

pub const AiCompletion = struct {
    allocator: std.mem.Allocator,
    prefix: []const u8,
    suffix: []const u8,
    language: []const u8,
    completion: []const u8,

    pub fn init(allocator: std.mem.Allocator) AiCompletion {
        return AiCompletion{ .allocator = allocator, .prefix = "", .suffix = "", .language = "", .completion = "" };
    }

    pub fn deinit(self: *AiCompletion) void {
        self.allocator.free(self.completion);
    }

    pub fn requestInline(self: *AiCompletion, prefix: []const u8, suffix: []const u8, language: []const u8) !void {
        _ = self; _ = prefix; _ = suffix; _ = language;
    }
};
