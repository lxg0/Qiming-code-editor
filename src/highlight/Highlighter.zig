const std = @import("std");
const Buffer = @import("../buffer/Buffer.zig").Buffer;
const Viewport = @import("../viewport/Viewport.zig").Viewport;

pub const Highlighter = struct {
    allocator: std.mem.Allocator,
    language: Language,

    pub const Language = enum {
        zig,
        rust,
        c,
        python,
        unknown,
    };

    pub fn init(allocator: std.mem.Allocator) !Highlighter {
        return Highlighter{
            .allocator = allocator,
            .language = .unknown,
        };
    }

    pub fn deinit(self: *Highlighter) void {
        _ = self;
    }

    pub fn setLanguage(self: *Highlighter, filename: []const u8) void {
        if (std.mem.endsWith(u8, filename, ".zig")) {
            self.language = .zig;
        } else if (std.mem.endsWith(u8, filename, ".rs")) {
            self.language = .rust;
        } else if (std.mem.endsWith(u8, filename, ".c") or std.mem.endsWith(u8, filename, ".h")) {
            self.language = .c;
        } else if (std.mem.endsWith(u8, filename, ".py")) {
            self.language = .python;
        } else {
            self.language = .unknown;
        }
    }

    pub fn highlight(_: *Highlighter, buffer: *Buffer, viewport: *Viewport) !void {
        var line_num: usize = viewport.top_line;
        while (line_num < viewport.top_line + viewport.height - 1) : (line_num += 1) {
            if (buffer.getLine(line_num)) |line| {
                try highlightLine(line_num, line, viewport);
            }
        }
    }

    fn highlightLine(line_num: usize, line: []const u8, viewport: *Viewport) !void {
        try viewport.drawLine(line_num, line);
    }
};
