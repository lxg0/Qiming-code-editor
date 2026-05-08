const std = @import("std");

pub const Selection = struct {
    start: usize,
    end: usize,
    reversed: bool,

    pub fn init(start: usize, end: usize) Selection {
        return Selection{
            .start = @min(start, end),
            .end = @max(start, end),
            .reversed = start > end,
        };
    }

    pub fn isEmpty(self: *const Selection) bool {
        return self.start == self.end;
    }

    pub fn len(self: *const Selection) usize {
        return self.end - self.start;
    }

    pub fn contains(self: *const Selection, position: usize) bool {
        return position >= self.start and position < self.end;
    }

    pub fn extend(self: *Selection, position: usize) void {
        if (position < self.start) {
            self.start = position;
            self.reversed = true;
        } else if (position > self.end) {
            self.end = position;
            self.reversed = false;
        }
    }

    pub fn collapseToStart(self: *Selection) void {
        self.end = self.start;
    }

    pub fn collapseToEnd(self: *Selection) void {
        self.start = self.end;
    }
};

pub const SelectionSet = struct {
    selections: std.array_list.Managed(Selection),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) SelectionSet {
        return SelectionSet{
            .selections = std.array_list.Managed(Selection).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SelectionSet) void {
        self.selections.deinit();
    }

    pub fn add(self: *SelectionSet, start: usize, end: usize) !void {
        try self.selections.append(Selection.init(start, end));
    }

    pub fn setPrimary(self: *SelectionSet, start: usize, end: usize) !void {
        if (self.selections.items.len > 0) {
            self.selections.items[0] = Selection.init(start, end);
        } else {
            try self.add(start, end);
        }
    }

    pub fn clear(self: *SelectionSet) void {
        self.selections.clearRetainingCapacity();
    }

    pub fn primary(self: *const SelectionSet) ?Selection {
        if (self.selections.items.len == 0) return null;
        return self.selections.items[0];
    }

    pub fn count(self: *const SelectionSet) usize {
        return self.selections.items.len;
    }

    pub fn addCursorAt(self: *SelectionSet, position: usize) !void {
        try self.add(position, position);
    }

    pub fn removeCursorAt(self: *SelectionSet, index: usize) void {
        if (index < self.selections.items.len) {
            _ = self.selections.orderedRemove(index);
        }
    }
};
