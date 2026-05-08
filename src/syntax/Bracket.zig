const std = @import("std");

pub const BracketPair = struct {
    open: u8,
    close: u8,
};

pub const BracketMatch = struct {
    open_pos: usize,
    close_pos: usize,
    kind: BracketPair,
};

pub const BracketEngine = struct {
    pairs: [3]BracketPair,

    pub fn init() BracketEngine {
        return BracketEngine{
            .pairs = .{
                .{ .open = '(', .close = ')' },
                .{ .open = '{', .close = '}' },
                .{ .open = '[', .close = ']' },
            },
        };
    }

    pub fn findMatching(self: *const BracketEngine, buffer: []const u8, position: usize) ?BracketMatch {
        if (position >= buffer.len) return null;
        const ch = buffer[position];
        for (self.pairs) |pair| {
            if (ch == pair.open) return self.findForward(buffer, position, pair);
            if (ch == pair.close) return self.findBackward(buffer, position, pair);
        }
        return null;
    }

    pub fn isBracket(self: *const BracketEngine, ch: u8) bool {
        for (self.pairs) |pair| {
            if (ch == pair.open or ch == pair.close) return true;
        }
        return false;
    }

    pub fn isOpenBracket(self: *const BracketEngine, ch: u8) ?BracketPair {
        for (self.pairs) |pair| {
            if (ch == pair.open) return pair;
        }
        return null;
    }

    fn findForward(self: *const BracketEngine, buffer: []const u8, pos: usize, pair: BracketPair) ?BracketMatch {
        var depth: usize = 1;
        var i = pos + 1;
        while (i < buffer.len) : (i += 1) {
            if (buffer[i] == pair.open) depth += 1;
            if (buffer[i] == pair.close) {
                depth -= 1;
                if (depth == 0) return BracketMatch{ .open_pos = pos, .close_pos = i, .kind = pair };
            }
        }
        return null;
    }

    fn findBackward(self: *const BracketEngine, buffer: []const u8, pos: usize, pair: BracketPair) ?BracketMatch {
        var depth: usize = 1;
        var i = pos;
        while (i > 0) {
            i -= 1;
            if (buffer[i] == pair.close) depth += 1;
            if (buffer[i] == pair.open) {
                depth -= 1;
                if (depth == 0) return BracketMatch{ .open_pos = i, .close_pos = pos, .kind = pair };
            }
        }
        return null;
    }
};
