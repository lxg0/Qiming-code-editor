const std = @import("std");
const PieceTable = @import("PieceTable.zig").PieceTable;
const simd = @import("simd.zig");

/// Unified Buffer interface - automatically selects optimal storage
pub const Buffer = struct {
    allocator: std.mem.Allocator,
    storage: Storage,
    file_path: ?[]u8,
    is_dirty: bool,
    encoding: Encoding,
    line_ending: LineEnding,

    pub const Storage = union(enum) {
        piece_table: PieceTable,
        gap_buffer: GapBuffer,
    };

    pub const Encoding = enum {
        utf8,
        gbk,
        big5,
        unknown,
    };

    pub const LineEnding = enum {
        lf,
        crlf,
        cr,
        mixed,
    };

    pub const GapBuffer = struct {
        data: []u8,
        gap_start: usize,
        gap_end: usize,
        len: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, initial: []const u8) !GapBuffer {
            const cap = @max(initial.len * 2, 256);
            var data = try allocator.alloc(u8, cap);
            @memcpy(data[0..initial.len], initial);
            return GapBuffer{
                .data = data,
                .gap_start = initial.len,
                .gap_end = cap,
                .len = initial.len,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *GapBuffer) void {
            self.allocator.free(self.data);
        }

        pub fn insert(self: *GapBuffer, position: usize, text: []const u8) !void {
            if (text.len == 0) return;
            self.moveGap(position);
            const gap_size = self.gap_end - self.gap_start;
            if (text.len > gap_size) {
                try self.grow(text.len - gap_size);
            }
            @memcpy(self.data[self.gap_start..][0..text.len], text);
            self.gap_start += text.len;
            self.len += text.len;
        }

        pub fn delete(self: *GapBuffer, position: usize, length: usize) !void {
            if (length == 0) return;
            self.moveGap(position);
            self.gap_end += length;
            self.len -= length;
        }

        pub fn getSlice(self: *const GapBuffer, position: usize, length: usize) ![]u8 {
            const result = try self.allocator.alloc(u8, length);
            var offset: usize = 0;
            var remaining = length;
            var pos = position;
            while (remaining > 0) {
                const chunk_start = if (pos < self.gap_start) pos else pos + (self.gap_end - self.gap_start);
                const chunk_end = if (pos + remaining <= self.gap_start)
                    pos + remaining
                else if (pos < self.gap_start)
                    self.gap_start
                else
                    pos + remaining + (self.gap_end - self.gap_start);
                const to_copy = @min(chunk_end - chunk_start, remaining);
                @memcpy(result[offset..][0..to_copy], self.data[chunk_start..][0..to_copy]);
                offset += to_copy;
                remaining -= to_copy;
                pos = if (pos < self.gap_start) self.gap_start else pos;
            }
            return result;
        }

        pub fn charAt(self: *const GapBuffer, position: usize) u8 {
            if (position >= self.len) return 0;
            const idx = if (position < self.gap_start) position else position + (self.gap_end - self.gap_start);
            return self.data[idx];
        }

        fn moveGap(self: *GapBuffer, position: usize) void {
            const gap_size = self.gap_end - self.gap_start;
            if (position == self.gap_start) return;
            if (position < self.gap_start) {
                const move_size = self.gap_start - position;
                const src = self.data[position..][0..move_size];
                const dst = self.data[self.gap_end - move_size..][0..move_size];
                @memcpy(dst, src);
                self.gap_start = position;
                self.gap_end = position + gap_size;
            } else {
                const move_size = position - self.gap_start;
                const src = self.data[self.gap_end..][0..move_size];
                const dst = self.data[self.gap_start..][0..move_size];
                @memcpy(dst, src);
                self.gap_start = position;
                self.gap_end = position + gap_size;
            }
        }

        fn grow(self: *GapBuffer, extra: usize) !void {
            const new_cap = self.data.len + extra + 256;
            var new_data = try self.allocator.alloc(u8, new_cap);
            const gap_size = self.gap_end - self.gap_start;
            @memcpy(new_data[0..self.gap_start], self.data[0..self.gap_start]);
            @memcpy(new_data[self.gap_start + gap_size + extra ..][0..self.data.len - self.gap_end], self.data[self.gap_end..]);
            self.allocator.free(self.data);
            self.data = new_data;
            self.gap_end = self.gap_start + gap_size + extra;
        }
    };

    pub fn init(allocator: std.mem.Allocator, initial: []const u8) !Buffer {
        const use_piece_table = initial.len > 1024 * 10; // >10KB use piece table
        return Buffer{
            .allocator = allocator,
            .storage = if (use_piece_table)
                .{ .piece_table = try PieceTable.init(allocator, initial) }
            else
                .{ .gap_buffer = try GapBuffer.init(allocator, initial) },
            .file_path = null,
            .is_dirty = false,
            .encoding = .utf8,
            .line_ending = .lf,
        };
    }

    pub fn deinit(self: *Buffer) void {
        switch (self.storage) {
            .piece_table => |*pt| pt.deinit(),
            .gap_buffer => |*gb| gb.deinit(),
        }
        if (self.file_path) |p| self.allocator.free(p);
    }

    pub fn len(self: *const Buffer) usize {
        return switch (self.storage) {
            .piece_table => |pt| pt.len(),
            .gap_buffer => |gb| gb.len,
        };
    }

    pub fn insert(self: *Buffer, position: usize, text: []const u8) !void {
        switch (self.storage) {
            .piece_table => |*pt| try pt.insert(position, text),
            .gap_buffer => |*gb| try gb.insert(position, text),
        }
        self.is_dirty = true;
        // Detect line ending
        if (std.mem.indexOf(u8, text, "\r\n") != null) {
            self.line_ending = .crlf;
        } else if (std.mem.indexOf(u8, text, "\r") != null) {
            self.line_ending = .cr;
        }
    }

    pub fn delete(self: *Buffer, position: usize, length: usize) !void {
        switch (self.storage) {
            .piece_table => |*pt| try pt.delete(position, length),
            .gap_buffer => |*gb| try gb.delete(position, length),
        }
        self.is_dirty = true;
    }

    pub fn getSlice(self: *const Buffer, position: usize, length: usize) ![]u8 {
        return switch (self.storage) {
            .piece_table => |*pt| try pt.getSlice(position, length),
            .gap_buffer => |*gb| try gb.getSlice(position, length),
        };
    }

    pub fn getLine(self: *const Buffer, line: usize) ![]u8 {
        return switch (self.storage) {
            .piece_table => |*pt| try pt.getLine(line),
            .gap_buffer => |gb| {
                var pos: usize = 0;
                var current_line: usize = 0;
                while (current_line < line and pos < gb.len) {
                    if (gb.charAt(pos) == '\n') current_line += 1;
                    pos += 1;
                }
                if (current_line < line) return &[_]u8{};
                const start = pos;
                while (pos < gb.len and gb.charAt(pos) != '\n') pos += 1;
                return try gb.getSlice(start, pos - start);
            },
        };
    }

    pub fn lineCount(self: *const Buffer) usize {
        return switch (self.storage) {
            .piece_table => |pt| pt.lineCount(),
            .gap_buffer => |gb| {
                var count: usize = 1;
                for (0..gb.len) |i| {
                    if (gb.charAt(i) == '\n') count += 1;
                }
                return count;
            },
        };
    }

    pub fn charAt(self: *const Buffer, position: usize) u8 {
        return switch (self.storage) {
            .piece_table => |*pt| pt.charAt(position),
            .gap_buffer => |*gb| gb.charAt(position),
        };
    }

    pub fn positionToLineCol(self: *const Buffer, position: usize) struct { line: usize, col: usize } {
        var line: usize = 0;
        for (0..@min(position, self.len())) |i| {
            if (self.charAt(i) == '\n') line += 1;
        }
        const line_start = self.lineStart(position);
        return .{ .line = line, .col = position - line_start };
    }

    pub fn lineColToPosition(self: *const Buffer, line: usize, col: usize) usize {
        var pos: usize = 0;
        var cur_line: usize = 0;
        while (cur_line < line and pos < self.len()) {
            if (self.charAt(pos) == '\n') cur_line += 1;
            pos += 1;
        }
        var cur_col: usize = 0;
        while (cur_col < col and pos < self.len() and self.charAt(pos) != '\n') {
            pos += 1;
            cur_col += 1;
        }
        return pos;
    }

    pub fn lineStart(self: *const Buffer, position: usize) usize {
        if (position == 0) return 0;
        var i: usize = position;
        while (i > 0) {
            i -= 1;
            if (self.charAt(i) == '\n') return i + 1;
        }
        return 0;
    }

    pub fn lineEnd(self: *const Buffer, position: usize) usize {
        var i: usize = position;
        while (i < self.len()) {
            if (self.charAt(i) == '\n') return i;
            i += 1;
        }
        return self.len();
    }

    pub fn getText(self: *const Buffer) ![]u8 {
        return self.getSlice(0, self.len());
    }

    pub fn setText(self: *Buffer, text: []const u8) !void {
        self.deinit();
        self.* = try init(self.allocator, text);
    }
};
