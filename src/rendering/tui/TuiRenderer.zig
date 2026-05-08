const std = @import("std");
const Theme = @import("../Theme.zig").Theme;
const Color = @import("../Theme.zig").Color;

pub const TuiRenderer = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    theme: Theme,
    buffer: std.array_list.Managed(u8),
    use_kitty: bool,

    pub fn init(allocator: std.mem.Allocator) TuiRenderer {
        return TuiRenderer{
            .allocator = allocator,
            .width = 80,
            .height = 24,
            .theme = Theme.default(),
            .buffer = std.array_list.Managed(u8).init(allocator),
            .use_kitty = false,
        };
    }

    pub fn deinit(self: *TuiRenderer) void {
        self.buffer.deinit();
    }

    pub fn setSize(self: *TuiRenderer, width: usize, height: usize) void {
        self.width = width;
        self.height = height;
    }

    pub fn setTheme(self: *TuiRenderer, theme: Theme) void {
        self.theme = theme;
    }

    pub fn enableAltScreen(self: *TuiRenderer) !void {
        try self.write("\x1b[?1049h");
    }

    pub fn disableAltScreen(self: *TuiRenderer) !void {
        try self.write("\x1b[?1049l");
    }

    pub fn enableRawMode(_: *TuiRenderer) !void {
        var termios = try std.posix.tcgetattr(0);
        termios.lflag.ICANON = false;
        termios.lflag.ECHO = false;
        termios.lflag.ISIG = false;
        termios.cflag.CSIZE = .CS8;
        termios.cc[6] = 1;
        termios.cc[5] = 0;
        try std.posix.tcsetattr(0, .NOW, termios);
    }

    pub fn disableRawMode(self: *TuiRenderer) !void {
        _ = self;
        var termios = try std.posix.tcgetattr(0);
        termios.lflag.ICANON = true;
        termios.lflag.ECHO = true;
        termios.lflag.ISIG = true;
        try std.posix.tcsetattr(0, .NOW, termios);
    }

    pub fn clear(self: *TuiRenderer) !void {
        try self.write("\x1b[2J");
        try self.write("\x1b[H");
    }

    pub fn write(self: *TuiRenderer, s: []const u8) !void {
        try self.buffer.appendSlice(s);
    }

    pub fn writeAnsi(self: *TuiRenderer, s: []const u8) !void {
        try self.write(s);
    }

    pub fn setCursorPos(self: *TuiRenderer, x: usize, y: usize) !void {
        try self.writef("\x1b[{d};{d}H", .{ y + 1, x + 1 });
    }

    pub fn setCursorVisible(self: *TuiRenderer, visible: bool) !void {
        try self.write(if (visible) "\x1b[?25h" else "\x1b[?25l");
    }

    pub fn setFgColor(self: *TuiRenderer, color: Color) !void {
        try self.writef("\x1b[38;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
    }

    pub fn setBgColor(self: *TuiRenderer, color: Color) !void {
        try self.writef("\x1b[48;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
    }

    pub fn resetStyle(self: *TuiRenderer) !void {
        try self.write("\x1b[0m");
    }

    pub fn writef(self: *TuiRenderer, comptime fmt: []const u8, args: anytype) !void {
        const s = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(s);
        try self.write(s);
    }

    pub fn drawChar(self: *TuiRenderer, ch: u8, x: usize, y: usize, fg: Color, bg: Color) !void {
        try self.setCursorPos(x, y);
        try self.setFgColor(fg);
        try self.setBgColor(bg);
        try self.write(&[_]u8{ch});
    }

    pub fn drawText(self: *TuiRenderer, text: []const u8, x: usize, y: usize, fg: Color, bg: Color) !void {
        try self.setCursorPos(x, y);
        try self.setFgColor(fg);
        try self.setBgColor(bg);
        try self.write(text);
    }

    pub fn drawRect(self: *TuiRenderer, x: usize, y: usize, w: usize, h: usize, color: Color) !void {
        var row: usize = 0;
        while (row < h) : (row += 1) {
            try self.setCursorPos(x, y + row);
            try self.setBgColor(color);
            var col: usize = 0;
            while (col < w) : (col += 1) try self.write(" ");
            try self.resetStyle();
        }
    }

    pub fn flush(self: *TuiRenderer) !void {
        // Write to stdout using Io
        var threaded_io = std.Io.Threaded.init(self.allocator, .{});
        defer threaded_io.deinit();
        const io: std.Io = threaded_io.io();
        try std.Io.File.stdout().writeStreamingAll(io, self.buffer.items);
        self.buffer.clearRetainingCapacity();
    }

    pub fn getSize(self: *TuiRenderer) !struct { width: usize, height: usize } {
        var ws: std.c.winsize = undefined;
        const TIOCGWINSZ: c_int = switch (@import("builtin").target.os.tag) {
            .macos => 0x40087468,
            .linux => 0x5413,
            else   => 0x5413,
        };
        const rc = std.c.ioctl(0, TIOCGWINSZ, &ws);
        if (rc == 0 and ws.col > 0 and ws.row > 0) {
            self.width = ws.col;
            self.height = ws.row;
        }
        return .{ .width = self.width, .height = self.height };
    }
};
