const std = @import("std");

pub const DialogButton = struct {
    label: []const u8,
    id: u64,
    default: bool,
};

pub const Dialog = struct {
    allocator: std.mem.Allocator,
    title: []const u8,
    message: []const u8,
    buttons: std.array_list.Managed(DialogButton),
    visible: bool,
    result: ?u64,

    pub fn init(allocator: std.mem.Allocator) Dialog {
        return Dialog{
            .allocator = allocator,
            .title = "",
            .message = "",
            .buttons = std.array_list.Managed(DialogButton).init(allocator),
            .visible = false,
            .result = null,
        };
    }

    pub fn deinit(self: *Dialog) void {
        self.buttons.deinit();
    }

    pub fn show(self: *Dialog, title: []const u8, message: []const u8) void {
        self.title = title;
        self.message = message;
        self.visible = true;
        self.result = null;
    }

    pub fn hide(self: *Dialog) void {
        self.visible = false;
    }

    pub fn addButton(self: *Dialog, label: []const u8, default: bool) !u64 {
        const id = @intCast(@import("../util/Async.zig").timestampMs());
        try self.buttons.append(.{ .label = label, .id = id, .default = default });
        return id;
    }
};
