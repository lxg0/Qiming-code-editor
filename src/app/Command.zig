const std = @import("std");
const Editor = @import("../editor/Editor.zig").Editor;

pub const Command = struct {
    name: []const u8,
    label: []const u8,
    shortcut: ?[]const u8,
    execute: *const fn (*Editor) void,
};

fn saveCmd(e: *Editor) void {
    e.saveFile(null) catch {};
}
fn undoCmd(e: *Editor) void {
    e.undo() catch {};
}
fn redoCmd(e: *Editor) void {
    e.redo() catch {};
}
fn cutCmd(e: *Editor) void {
    e.cut() catch {};
}
fn copyCmd(e: *Editor) void {
    e.copy() catch {};
}
fn pasteCmd(e: *Editor) void {
    e.paste() catch {};
}

pub const CommandRegistry = struct {
    allocator: std.mem.Allocator,
    commands: std.StringHashMap(Command),

    pub fn init(allocator: std.mem.Allocator) CommandRegistry {
        return CommandRegistry{ .allocator = allocator, .commands = std.StringHashMap(Command).init(allocator) };
    }

    pub fn deinit(self: *CommandRegistry) void {
        self.commands.deinit();
    }

    pub fn register(self: *CommandRegistry, command: Command) !void {
        try self.commands.put(command.name, command);
    }

    pub fn execute(self: *const CommandRegistry, name: []const u8, editor: *Editor) bool {
        if (self.commands.get(name)) |cmd| {
            cmd.execute(editor);
            return true;
        }
        return false;
    }

    pub fn registerDefaults(self: *CommandRegistry) !void {
        try self.register(.{ .name = "editor.save", .label = "保存", .shortcut = "Ctrl+S", .execute = &saveCmd });
        try self.register(.{ .name = "editor.undo", .label = "撤销", .shortcut = "Ctrl+Z", .execute = &undoCmd });
        try self.register(.{ .name = "editor.redo", .label = "重做", .shortcut = "Ctrl+Y", .execute = &redoCmd });
        try self.register(.{ .name = "editor.cut", .label = "剪切", .shortcut = "Ctrl+X", .execute = &cutCmd });
        try self.register(.{ .name = "editor.copy", .label = "复制", .shortcut = "Ctrl+C", .execute = &copyCmd });
        try self.register(.{ .name = "editor.paste", .label = "粘贴", .shortcut = "Ctrl+V", .execute = &pasteCmd });
    }
};
