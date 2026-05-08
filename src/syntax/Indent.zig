const std = @import("std");

pub const IndentEngine = struct {
    tab_size: u8,
    use_tabs: bool,

    pub fn init() IndentEngine {
        return IndentEngine{ .tab_size = 4, .use_tabs = false };
    }

    pub fn indentString(self: *const IndentEngine, level: usize) []const u8 {
        _ = self;
        _ = level;
        return "    "; // simplified
    }

    pub fn computeIndent(self: *const IndentEngine, line: []const u8) usize {
        var count: usize = 0;
        for (line) |c| {
            if (c == ' ') count += 1;
            else if (c == '\t') count += self.tab_size;
            else break;
        }
        return count / self.tab_size;
    }

    pub fn shouldIncreaseIndent(self: *const IndentEngine, line: []const u8) bool {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) return false;
        const last = trimmed[trimmed.len - 1];
        return last == '{' or last == '[' or last == '(' or last == ':';
    }

    pub fn shouldDecreaseIndent(self: *const IndentEngine, line: []const u8) bool {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) return false;
        return trimmed[0] == '}' or trimmed[0] == ']' or trimmed[0] == ')';
    }
};
