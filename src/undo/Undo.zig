const std = @import("std");
const Buffer = @import("../buffer/Buffer.zig").Buffer;

pub const Undo = struct {
    allocator: std.mem.Allocator,
    stack: std.array_list.AlignedManaged(Snapshot, null),
    index: usize = 0,

    pub const Snapshot = struct {
        data: []u8,
        cursor: usize,
    };

    pub fn init(allocator: std.mem.Allocator) !Undo {
        return Undo{
            .allocator = allocator,
            .stack = std.array_list.AlignedManaged(Snapshot, null).init(allocator),
        };
    }

    pub fn deinit(self: *Undo) void {
        for (self.stack.items) |snapshot| {
            self.allocator.free(snapshot.data);
        }
        self.stack.deinit();
    }

    pub fn saveSnapshot(self: *Undo, buffer: *Buffer) !void {
        try self.push(buffer);
    }

    pub fn push(self: *Undo, buffer: *Buffer) !void {
        while (self.stack.items.len > self.index) {
            if (self.stack.pop()) |last| {
                self.allocator.free(last.data);
            }
        }

        const data = try self.allocator.dupe(u8, buffer.data.items);
        try self.stack.append(Snapshot{
            .data = data,
            .cursor = buffer.cursor,
        });
        self.index = self.stack.items.len;
    }

    pub fn undo(self: *Undo, buffer: *Buffer) !void {
        if (self.index == 0) return;
        self.index -= 1;
        const snapshot = self.stack.items[self.index];
        try buffer.data.resize(snapshot.data.len);
        @memcpy(buffer.data.items, snapshot.data);
        buffer.cursor = snapshot.cursor;
    }

    pub fn redo(self: *Undo, buffer: *Buffer) !void {
        if (self.index >= self.stack.items.len) return;
        const snapshot = self.stack.items[self.index];
        try buffer.data.resize(snapshot.data.len);
        @memcpy(buffer.data.items, snapshot.data);
        buffer.cursor = snapshot.cursor;
        self.index += 1;
    }
};
