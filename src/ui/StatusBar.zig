const std = @import("std");

pub const StatusBarItem = struct {
    label: []const u8,
    value: []const u8,
    alignment: enum { left, right },
};

pub const StatusBar = struct {
    allocator: std.mem.Allocator,
    height: f32,
    left_items: std.array_list.Managed(StatusBarItem),
    right_items: std.array_list.Managed(StatusBarItem),
    cursor_line: usize,
    cursor_col: usize,
    language: []const u8,
    encoding: []const u8,
    line_ending: []const u8,
    is_dirty: bool,
    mode: []const u8,

    pub fn init(allocator: std.mem.Allocator) StatusBar {
        return StatusBar{
            .allocator = allocator,
            .height = 24,
            .left_items = std.array_list.Managed(StatusBarItem).init(allocator),
            .right_items = std.array_list.Managed(StatusBarItem).init(allocator),
            .cursor_line = 1,
            .cursor_col = 1,
            .language = "纯文本",
            .encoding = "UTF-8",
            .line_ending = "LF",
            .is_dirty = false,
            .mode = "插入",
        };
    }

    pub fn deinit(self: *StatusBar) void {
        self.left_items.deinit();
        self.right_items.deinit();
    }

    pub fn setCursorPosition(self: *StatusBar, line: usize, col: usize) void {
        self.cursor_line = line;
        self.cursor_col = col;
    }

    pub fn setLanguage(self: *StatusBar, language: []const u8) void {
        self.language = language;
    }

    pub fn setEncoding(self: *StatusBar, encoding: []const u8) void {
        self.encoding = encoding;
    }

    pub fn setLineEnding(self: *StatusBar, ending: []const u8) void {
        self.line_ending = ending;
    }

    pub fn setModeName(self: *StatusBar, mode: []const u8) void {
        self.mode = mode;
    }
};
