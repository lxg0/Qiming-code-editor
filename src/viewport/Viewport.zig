const std = @import("std");
const Buffer = @import("../buffer/Buffer.zig").Buffer;

const InputResize = struct {
    width: usize,
    height: usize,
};

pub const Viewport = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    width: usize = 80,
    height: usize = 24,
    top_line: usize = 0,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) !Viewport {
        return Viewport{
            .allocator = allocator,
            .io = io,
        };
    }

    pub fn deinit(self: *Viewport) void {
        _ = self;
    }

    fn writeStdout(self: *Viewport, s: []const u8) !void {
        try std.Io.File.stdout().writeStreamingAll(self.io, s);
    }

    pub fn enterAlternateScreen(self: *Viewport) !void {
        try self.writeStdout("\x1b[?1049h");
    }

    pub fn exitAlternateScreen(self: *Viewport) !void {
        try self.writeStdout("\x1b[?1049l");
    }

    pub fn enableRawMode(_: *Viewport) !void {
        var termios = try std.posix.tcgetattr(0);
        termios.lflag.ICANON = false;
        termios.lflag.ECHO = false;
        termios.lflag.ISIG = false;
        termios.cflag.CSIZE = .CS8;
        termios.cc[6] = 1; // VMIN
        termios.cc[5] = 0; // VTIME
        try std.posix.tcsetattr(0, .NOW, termios);
    }

    pub fn disableRawMode(_: *Viewport) !void {
        var termios = try std.posix.tcgetattr(0);
        termios.lflag.ICANON = true;
        termios.lflag.ECHO = true;
        termios.lflag.ISIG = true;
        try std.posix.tcsetattr(0, .NOW, termios);
    }

    pub fn clearScreen(self: *Viewport) !void {
        try self.writeStdout("\x1b[2J");
    }

    pub fn drawStatusBar(self: *Viewport, line_count: usize) !void {
        const line = try std.fmt.allocPrint(self.allocator, "\x1b[{};1H\x1b[7m Edit - {} lines \x1b[0m{s}", .{self.height, line_count, std.mem.zeroes([100]u8)[0..self.width - 20]});
        defer self.allocator.free(line);
        try self.writeStdout(line);
    }

    pub fn drawCursor(self: *Viewport, cursor_pos: usize) !void {
        const cursor = try std.fmt.allocPrint(std.heap.page_allocator, "\x1b[{};{}H", .{1, cursor_pos + 1});
        defer std.heap.page_allocator.free(cursor);
        try self.writeStdout(cursor);
    }

    pub fn resize(self: *Viewport, size: InputResize) void {
        self.width = size.width;
        self.height = size.height;
    }

    pub fn flush(self: *Viewport) !void {
        var buf: [1]u8 = undefined;
        var writer = std.Io.File.stdout().writer(self.io, &buf);
        try writer.flush();
    }

    pub fn drawLine(self: *Viewport, line_num: usize, text: []const u8) !void {
        const y = line_num - self.top_line + 1;
        if (y < 1 or y >= self.height) return;
        
        const display_text = if (text.len > self.width) text[0..self.width] else text;
        const line = try std.fmt.allocPrint(self.allocator, "\x1b[{};1H{s}", .{y, display_text});
        defer self.allocator.free(line);
        try self.writeStdout(line);
        
        if (text.len <= self.width) {
            try self.writeStdout("\x1b[K");
        }
    }
};
