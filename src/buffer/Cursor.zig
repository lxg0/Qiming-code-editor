const std = @import("std");

pub const Cursor = struct {
    position: usize,
    goal_column: usize,
    preferred_x: f32,

    pub fn init() Cursor {
        return Cursor{ .position = 0, .goal_column = 0, .preferred_x = 0 };
    }

    pub fn moveLeft(self: *Cursor) void {
        if (self.position > 0) self.position -= 1;
    }

    pub fn moveRight(self: *Cursor, max_pos: usize) void {
        if (self.position < max_pos) self.position += 1;
    }

    pub fn moveUp(self: *Cursor, line_start: usize, prev_line_length: usize) void {
        if (self.position == 0) return;
        const col = self.colInLine(line_start);
        self.position = if (col <= prev_line_length)
            (line_start - prev_line_length - 1) + col
        else
            line_start - 1;
    }

    pub fn moveDown(self: *Cursor, line_end: usize, next_line_length: usize) void {
        const max_pos = line_end + next_line_length;
        if (self.position >= max_pos) return;
        const col = self.colInLine(line_end);
        self.position = (line_end + 1) + @min(col, next_line_length);
    }

    pub fn moveToLineStart(self: *Cursor, line_start: usize) void {
        self.position = line_start;
    }

    pub fn moveToLineEnd(self: *Cursor, line_end: usize) void {
        self.position = line_end;
    }

    pub fn colInLine(self: *Cursor, line_start: usize) usize {
        return self.position - line_start;
    }

    pub fn setPosition(self: *Cursor, pos: usize) void {
        self.position = pos;
    }
};
