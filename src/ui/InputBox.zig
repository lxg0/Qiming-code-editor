const std = @import("std");

pub const InputBox = struct {
    allocator: std.mem.Allocator,
    buffer: std.array_list.Managed(u8),
    cursor_pos: usize,
    placeholder: []const u8,
    visible: bool,
    title: []const u8,
    password_mode: bool,
    on_submit: ?*const fn ([]const u8) void,

    pub fn init(allocator: std.mem.Allocator) InputBox {
        return InputBox{
            .allocator = allocator,
            .buffer = std.array_list.Managed(u8).init(allocator),
            .cursor_pos = 0,
            .placeholder = "",
            .visible = false,
            .title = "",
            .password_mode = false,
            .on_submit = null,
        };
    }

    pub fn deinit(self: *InputBox) void {
        self.buffer.deinit();
    }

    pub fn show(self: *InputBox, title: []const u8, placeholder: []const u8, callback: *const fn ([]const u8) void) void {
        self.title = title;
        self.placeholder = placeholder;
        self.visible = true;
        self.buffer.clearRetainingCapacity();
        self.cursor_pos = 0;
        self.on_submit = callback;
    }

    pub fn hide(self: *InputBox) void {
        self.visible = false;
    }

    pub fn addChar(self: *InputBox, c: u8) !void {
        try self.buffer.insert(self.cursor_pos, &[_]u8{c});
        self.cursor_pos += 1;
    }

    pub fn deleteChar(self: *InputBox) void {
        if (self.cursor_pos > 0) {
            self.cursor_pos -= 1;
            _ = self.buffer.orderedRemove(self.cursor_pos);
        }
    }

    pub fn clear(self: *InputBox) void {
        self.buffer.clearRetainingCapacity();
        self.cursor_pos = 0;
    }

    pub fn submit(self: *InputBox) void {
        if (self.on_submit) |cb| cb(self.buffer.items);
        self.hide();
    }
};
