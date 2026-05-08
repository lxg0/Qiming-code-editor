const std = @import("std");
const Editor = @import("../editor/Editor.zig").Editor;

pub const PluginApi = struct {
    editor: *Editor,
    allocator: std.mem.Allocator,
    version: []const u8,

    pub fn init(editor: *Editor, allocator: std.mem.Allocator) PluginApi {
        return PluginApi{ .editor = editor, .allocator = allocator, .version = "1.0.0" };
    }

    pub fn getActiveDocument(self: *const PluginApi) void {
        _ = self;
    }

    pub fn insertText(self: *const PluginApi, text: []const u8) void {
        _ = self; _ = text;
    }

    pub fn showMessage(self: *const PluginApi, msg: []const u8) void {
        _ = self; _ = msg;
    }
};
