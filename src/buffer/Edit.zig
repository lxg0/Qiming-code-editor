const std = @import("std");
const Buffer = @import("Buffer.zig").Buffer;

pub const EditKind = enum {
    insert,
    delete,
    replace,
};

pub const Edit = struct {
    kind: EditKind,
    position: usize,
    text: []u8,
    deleted_text: []u8,
    timestamp: u64,

    pub fn deinit(self: *Edit, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
        allocator.free(self.deleted_text);
    }

    pub fn apply(self: *const Edit, buffer: *Buffer) !void {
        switch (self.kind) {
            .insert => try buffer.insert(self.position, self.text),
            .delete => try buffer.delete(self.position, self.deleted_text.len),
            .replace => {
                try buffer.delete(self.position, self.deleted_text.len);
                try buffer.insert(self.position, self.text);
            },
        }
    }

    pub fn revert(self: *const Edit, buffer: *Buffer) !void {
        switch (self.kind) {
            .insert => try buffer.delete(self.position, self.text.len),
            .delete => try buffer.insert(self.position, self.deleted_text),
            .replace => {
                try buffer.delete(self.position, self.text.len);
                try buffer.insert(self.position, self.deleted_text);
            },
        }
    }
};

pub const EditBatch = struct {
    edits: std.array_list.Managed(Edit),
    allocator: std.mem.Allocator,
    label: []const u8,

    pub fn init(allocator: std.mem.Allocator, label: []const u8) EditBatch {
        return EditBatch{
            .edits = std.array_list.Managed(Edit).init(allocator),
            .allocator = allocator,
            .label = label,
        };
    }

    pub fn deinit(self: *EditBatch) void {
        for (self.edits.items) |*e| e.deinit(self.allocator);
        self.edits.deinit();
    }

    pub fn push(self: *EditBatch, kind: EditKind, position: usize, text: []const u8, deleted_text: []const u8) !void {
        try self.edits.append(Edit{
            .kind = kind,
            .position = position,
            .text = try self.allocator.dupe(u8, text),
            .deleted_text = try self.allocator.dupe(u8, deleted_text),
            .timestamp = @intFromFloat(@as(f64, @floatFromInt(@import("../util/Async.zig").timestampMs())) / 1e9),
        });
    }

    pub fn apply(self: *const EditBatch, buffer: *Buffer) !void {
        for (self.edits.items) |e| try e.apply(buffer);
    }

    pub fn revert(self: *const EditBatch, buffer: *Buffer) !void {
        var i: usize = self.edits.items.len;
        while (i > 0) {
            i -= 1;
            try self.edits.items[i].revert(buffer);
        }
    }
};
