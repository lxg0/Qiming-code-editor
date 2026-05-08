const std = @import("std");
const Buffer = @import("Buffer.zig").Buffer;
const Edit = @import("Edit.zig").Edit;
const EditBatch = @import("Edit.zig").EditBatch;

pub const UndoManager = struct {
    allocator: std.mem.Allocator,
    undo_stack: std.array_list.Managed(EditBatch),
    redo_stack: std.array_list.Managed(EditBatch),
    max_history: usize,
    save_point: usize,

    pub fn init(allocator: std.mem.Allocator, max_history: usize) UndoManager {
        return UndoManager{
            .allocator = allocator,
            .undo_stack = std.array_list.Managed(EditBatch).init(allocator),
            .redo_stack = std.array_list.Managed(EditBatch).init(allocator),
            .max_history = max_history,
            .save_point = 0,
        };
    }

    pub fn deinit(self: *UndoManager) void {
        for (self.undo_stack.items) |*b| b.deinit();
        self.undo_stack.deinit();
        for (self.redo_stack.items) |*b| b.deinit();
        self.redo_stack.deinit();
    }

    pub fn record(self: *UndoManager, batch: EditBatch) !void {
        // Clear redo stack on new edit
        for (self.redo_stack.items) |*b| b.deinit();
        self.redo_stack.clearRetainingCapacity();

        try self.undo_stack.append(batch);

        // Trim history
        while (self.undo_stack.items.len > self.max_history) {
            var oldest = self.undo_stack.orderedRemove(0);
            oldest.deinit();
            if (self.save_point > 0) self.save_point -= 1;
        }
    }

    pub fn undo(self: *UndoManager, buffer: *Buffer) !void {
        if (self.undo_stack.items.len == 0) return;
        var batch = self.undo_stack.pop().?;
        try batch.revert(buffer);
        try self.redo_stack.append(batch);
    }

    pub fn redo(self: *UndoManager, buffer: *Buffer) !void {
        if (self.redo_stack.items.len == 0) return;
        var batch = self.redo_stack.pop().?;
        try batch.apply(buffer);
        try self.undo_stack.append(batch);
    }

    pub fn markSavePoint(self: *UndoManager) void {
        self.save_point = self.undo_stack.items.len;
    }

    pub fn isSavePoint(self: *const UndoManager) bool {
        return self.undo_stack.items.len == self.save_point;
    }

    pub fn canUndo(self: *const UndoManager) bool {
        return self.undo_stack.items.len > 0;
    }

    pub fn canRedo(self: *const UndoManager) bool {
        return self.redo_stack.items.len > 0;
    }

    pub fn clear(self: *UndoManager) void {
        for (self.undo_stack.items) |*b| b.deinit();
        self.undo_stack.clearRetainingCapacity();
        for (self.redo_stack.items) |*b| b.deinit();
        self.redo_stack.clearRetainingCapacity();
        self.save_point = 0;
    }
};
