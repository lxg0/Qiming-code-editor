const std = @import("std");
const Cursor = @import("../buffer/Cursor.zig").Cursor;
const Selection = @import("../buffer/Selection.zig").Selection;

pub const MultiCursor = struct {
    cursors: std.array_list.Managed(Cursor),
    selections: std.array_list.Managed(Selection),
    allocator: std.mem.Allocator,
    active_index: usize,

    pub fn init(allocator: std.mem.Allocator) MultiCursor {
        var mc = MultiCursor{
            .cursors = std.array_list.Managed(Cursor).init(allocator),
            .selections = std.array_list.Managed(Selection).init(allocator),
            .allocator = allocator,
            .active_index = 0,
        };
        mc.cursors.append(Cursor.init()) catch {};
        return mc;
    }

    pub fn deinit(self: *MultiCursor) void {
        self.cursors.deinit();
        self.selections.deinit();
    }

    pub fn active(self: *const MultiCursor) *const Cursor {
        return &self.cursors.items[self.active_index];
    }

    pub fn activeMut(self: *MultiCursor) *Cursor {
        return &self.cursors.items[self.active_index];
    }

    pub fn addCursorAt(self: *MultiCursor, position: usize) !void {
        var cursor = Cursor.init();
        cursor.setPosition(position);
        try self.cursors.append(cursor);
    }

    pub fn removeActive(self: *MultiCursor) void {
        if (self.cursors.items.len > 1) {
            _ = self.cursors.orderedRemove(self.active_index);
            if (self.active_index >= self.cursors.items.len) {
                self.active_index = self.cursors.items.len - 1;
            }
        }
    }

    pub fn removeAllButActive(self: *MultiCursor) void {
        const active_pos = self.cursors.items[self.active_index].position;
        self.cursors.clearRetainingCapacity();
        var cursor = Cursor.init();
        cursor.setPosition(active_pos);
        self.cursors.append(cursor) catch {};
        self.active_index = 0;
    }

    pub fn selectNextOccurrence(_: *MultiCursor, _: []const u8, _: []const u8) !void {
        // TODO: Implement find-next-occurrence for multi-cursor
    }

    pub fn forEachCursor(self: *const MultiCursor, callback: *const fn (*const Cursor) void) void {
        for (self.cursors.items) |*c| callback(c);
    }

    pub fn forEachCursorMut(self: *MultiCursor, callback: *const fn (*Cursor) void) void {
        for (self.cursors.items) |*c| callback(c);
    }

    pub fn count(self: *const MultiCursor) usize {
        return self.cursors.items.len;
    }

    pub fn hasMultiple(self: *const MultiCursor) bool {
        return self.cursors.items.len > 1;
    }
};
