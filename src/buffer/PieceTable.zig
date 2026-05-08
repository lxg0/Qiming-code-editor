const std = @import("std");

/// Piece Table data structure for efficient text editing
/// Stores text as a sequence of "pieces" referencing either original or added buffer
pub const PieceTable = struct {
    allocator: std.mem.Allocator,
    original: []u8,
    added: std.array_list.Managed(u8),
    pieces: std.array_list.Managed(Piece),
    length: usize,

    pub const Piece = struct {
        buffer: enum { original, added },
        start: usize,
        length: usize,
    };

    pub fn init(allocator: std.mem.Allocator, initial_text: []const u8) !PieceTable {
        var pt = PieceTable{
            .allocator = allocator,
            .original = try allocator.dupe(u8, initial_text),
            .added = std.array_list.Managed(u8).init(allocator),
            .pieces = std.array_list.Managed(Piece).init(allocator),
            .length = initial_text.len,
        };
        if (initial_text.len > 0) {
            try pt.pieces.append(Piece{ .buffer = .original, .start = 0, .length = initial_text.len });
        }
        return pt;
    }

    pub fn deinit(self: *PieceTable) void {
        self.allocator.free(self.original);
        self.added.deinit();
        self.pieces.deinit();
    }

    pub fn len(self: *const PieceTable) usize {
        return self.length;
    }

    pub fn insert(self: *PieceTable, position: usize, text: []const u8) !void {
        if (text.len == 0) return;
        const add_start = self.added.items.len;
        try self.added.appendSlice(text);
        try self.splitAt(position);
        try self.pieces.insert(
            self.pieceIndex(position) + 1,
            Piece{ .buffer = .added, .start = add_start, .length = text.len },
        );
        self.length += text.len;
    }

    pub fn delete(self: *PieceTable, position: usize, length: usize) !void {
        if (length == 0) return;
        const start_idx = self.pieceIndex(position);
        const end_idx = self.pieceIndex(position + length);
        const start_offset = position - self.piecePosition(start_idx);
        const end_offset = (position + length) - self.piecePosition(end_idx);

        // Trim start piece
        var piece = &self.pieces.items[start_idx];
        if (start_offset > 0) {
            piece.length = start_offset;
        }
        // Trim end piece
        if (end_idx > start_idx) {
            piece = &self.pieces.items[end_idx];
            if (end_offset < piece.length) {
                piece.start += end_offset;
                piece.length -= end_offset;
            }
        }
        // Remove middle pieces
        const remove_start = if (start_offset > 0) start_idx + 1 else start_idx;
        const remove_end = if (end_offset < self.pieces.items[end_idx].length) end_idx else end_idx + 1;
        if (remove_end > remove_start) {
            self.pieces.replaceRange(remove_start, remove_end - remove_start, &.{}) catch {};
        }
        self.length -= length;
    }

    pub fn getText(self: *const PieceTable) ![]u8 {
        const result = try self.allocator.alloc(u8, self.length);
        var offset: usize = 0;
        for (self.pieces.items) |piece| {
            const src = switch (piece.buffer) {
                .original => self.original[piece.start..][0..piece.length],
                .added => self.added.items[piece.start..][0..piece.length],
            };
            @memcpy(result[offset..][0..piece.length], src);
            offset += piece.length;
        }
        return result;
    }

    pub fn getSlice(self: *const PieceTable, position: usize, length: usize) ![]u8 {
        const result = try self.allocator.alloc(u8, length);
        var offset: usize = 0;
        var remaining = length;
        var i = self.pieceIndex(position);
        var piece_offset = position - self.piecePosition(i);

        while (remaining > 0 and i < self.pieces.items.len) : (i += 1) {
            const piece = self.pieces.items[i];
            const available = piece.length - piece_offset;
            const to_copy = @min(available, remaining);
            const src = switch (piece.buffer) {
                .original => self.original[piece.start + piece_offset..][0..to_copy],
                .added => self.added.items[piece.start + piece_offset..][0..to_copy],
            };
            @memcpy(result[offset..][0..to_copy], src);
            offset += to_copy;
            remaining -= to_copy;
            piece_offset = 0;
        }
        return result;
    }

    pub fn getLine(self: *const PieceTable, line: usize) ![]u8 {
        var pos: usize = 0;
        var current_line: usize = 0;
        while (current_line < line and pos < self.length) {
            if (self.charAt(pos) == '\n') current_line += 1;
            pos += 1;
        }
        if (current_line < line) return &[_]u8{};
        const start = pos;
        while (pos < self.length and self.charAt(pos) != '\n') pos += 1;
        const end = pos;
        return self.getSlice(start, end - start);
    }

    pub fn lineCount(self: *const PieceTable) usize {
        var count: usize = 1;
        for (self.pieces.items) |piece| {
            const src = switch (piece.buffer) {
                .original => self.original[piece.start..][0..piece.length],
                .added => self.added.items[piece.start..][0..piece.length],
            };
            count += std.mem.count(u8, src, "\n");
        }
        return count;
    }

    fn charAt(self: *const PieceTable, position: usize) u8 {
        if (position >= self.length) return 0;
        const idx = self.pieceIndex(position);
        const piece = self.pieces.items[idx];
        const offset = position - self.piecePosition(idx);
        return switch (piece.buffer) {
            .original => self.original[piece.start + offset],
            .added => self.added.items[piece.start + offset],
        };
    }

    fn piecePosition(self: *const PieceTable, index: usize) usize {
        var pos: usize = 0;
        for (self.pieces.items[0..index]) |p| pos += p.length;
        return pos;
    }

    fn pieceIndex(self: *const PieceTable, position: usize) usize {
        var pos: usize = 0;
        for (self.pieces.items, 0..) |piece, i| {
            pos += piece.length;
            if (pos > position) return i;
        }
        return if (self.pieces.items.len > 0) self.pieces.items.len - 1 else 0;
    }

    fn splitAt(self: *PieceTable, position: usize) !void {
        if (position == 0 or position >= self.length) return;
        const idx = self.pieceIndex(position);
        var pos: usize = 0;
        for (self.pieces.items[0..idx]) |p| pos += p.length;
        const piece = &self.pieces.items[idx];
        const offset = position - pos;
        if (offset > 0 and offset < piece.length) {
            try self.pieces.insert(idx + 1, Piece{
                .buffer = piece.buffer,
                .start = piece.start + offset,
                .length = piece.length - offset,
            });
            piece.length = offset;
        }
    }
};

test "PieceTable basic operations" {
    const alloc = std.testing.allocator;
    var pt = try PieceTable.init(alloc, "Hello World");
    defer pt.deinit();
    try std.testing.expectEqual(@as(usize, 11), pt.len());
    try std.testing.expectEqual(@as(usize, 1), pt.lineCount());
}
