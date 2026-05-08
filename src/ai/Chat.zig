const std = @import("std");

pub const ChatMessage = struct {
    role: enum { user, assistant, system },
    content: []const u8,
    timestamp: i64,
};

pub const ChatPanel = struct {
    allocator: std.mem.Allocator,
    messages: std.array_list.Managed(ChatMessage),
    input_buffer: std.array_list.Managed(u8),
    visible: bool,

    pub fn init(allocator: std.mem.Allocator) ChatPanel {
        return ChatPanel{
            .allocator = allocator,
            .messages = std.array_list.Managed(ChatMessage).init(allocator),
            .input_buffer = std.array_list.Managed(u8).init(allocator),
            .visible = false,
        };
    }

    pub fn deinit(self: *ChatPanel) void {
        self.messages.deinit();
        self.input_buffer.deinit();
    }

    pub fn toggle(self: *ChatPanel) void {
        self.visible = !self.visible;
    }

    pub fn addMessage(self: *ChatPanel, role: ChatMessage.role, content: []const u8) !void {
        try self.messages.append(.{ .role = role, .content = try self.allocator.dupe(u8, content), .timestamp = std.time.timestamp() });
    }

    pub fn sendMessage(self: *ChatPanel, text: []const u8) !void {
        try self.addMessage(.user, text);
        try self.addMessage(.assistant, "(AI 思考中...)");
    }
};
