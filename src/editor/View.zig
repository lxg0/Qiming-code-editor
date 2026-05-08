const std = @import("std");
const Document = @import("Document.zig").Document;
const Cursor = @import("../buffer/Cursor.zig").Cursor;
const Selection = @import("../buffer/Selection.zig").Selection;

pub const View = struct {
    allocator: std.mem.Allocator,
    document: *Document,
    cursors: std.array_list.Managed(Cursor),
    selections: std.array_list.Managed(Selection),
    scroll_x: f32,
    scroll_y: f32,
    viewport_width: f32,
    viewport_height: f32,
    line_height: f32,
    char_width: f32,
    show_line_numbers: bool,
    show_gutter: bool,
    word_wrap: bool,
    tab_size: u8,

    pub fn init(allocator: std.mem.Allocator, document: *Document) !View {
        var view = View{
            .allocator = allocator,
            .document = document,
            .cursors = std.array_list.Managed(Cursor).init(allocator),
            .selections = std.array_list.Managed(Selection).init(allocator),
            .scroll_x = 0,
            .scroll_y = 0,
            .viewport_width = 800,
            .viewport_height = 600,
            .line_height = 22,
            .char_width = 8,
            .show_line_numbers = true,
            .show_gutter = true,
            .word_wrap = true,
            .tab_size = 4,
        };
        try view.cursors.append(Cursor.init());
        return view;
    }

    pub fn deinit(self: *View) void {
        self.cursors.deinit();
        self.selections.deinit();
    }

    pub fn primaryCursor(self: *const View) *const Cursor {
        return &self.cursors.items[0];
    }

    pub fn primaryCursorMut(self: *View) *Cursor {
        return &self.cursors.items[0];
    }

    pub fn setViewportSize(self: *View, width: f32, height: f32) void {
        self.viewport_width = width;
        self.viewport_height = height;
    }

    pub fn scrollToCursor(self: *View) void {
        const cursor = self.primaryCursor();
        const pos = cursor.position;
        const line_col = self.document.buffer.positionToLineCol(pos);
        const cursor_x: f32 = @floatFromInt(line_col.col * @as(usize, @intFromFloat(self.char_width)));
        const cursor_y: f32 = @floatFromInt(line_col.line * @as(usize, @intFromFloat(self.line_height)));

        if (cursor_x < self.scroll_x) {
            self.scroll_x = cursor_x;
        } else if (cursor_x > self.scroll_x + self.viewport_width - self.char_width * 4) {
            self.scroll_x = cursor_x - self.viewport_width + self.char_width * 8;
        }

        if (cursor_y < self.scroll_y) {
            self.scroll_y = cursor_y;
        } else if (cursor_y > self.scroll_y + self.viewport_height - self.line_height * 2) {
            self.scroll_y = cursor_y - self.viewport_height + self.line_height * 4;
        }
    }

    pub fn getVisibleLineRange(self: *const View) struct { start: usize, end: usize } {
        const start_line = @as(usize, @intFromFloat(self.scroll_y / self.line_height));
        const visible_count = @as(usize, @intFromFloat(self.viewport_height / self.line_height)) + 2;
        return .{
            .start = start_line,
            .end = start_line + visible_count,
        };
    }

    pub fn coordsToPosition(self: *const View, screen_x: f32, screen_y: f32) usize {
        const col = @as(usize, @intFromFloat((screen_x + self.scroll_x) / self.char_width));
        const line = @as(usize, @intFromFloat((screen_y + self.scroll_y) / self.line_height));
        return self.document.buffer.lineColToPosition(line, col);
    }

    pub fn addCursor(self: *View, position: usize) !void {
        var cursor = Cursor.init();
        cursor.setPosition(position);
        try self.cursors.append(cursor);
    }

    pub fn removeCursor(self: *View, index: usize) void {
        if (index > 0 and index < self.cursors.items.len) {
            _ = self.cursors.orderedRemove(index);
        }
    }

    pub fn addSelection(self: *View, start: usize, end: usize) !void {
        try self.selections.append(Selection.init(start, end));
    }

    pub fn clearSelections(self: *View) void {
        self.selections.clearRetainingCapacity();
    }
};
