const std = @import("std");

pub const TerminalCell = struct {
    char: u8,
    fg: u32,
    bg: u32,
    bold: bool,
    italic: bool,
    underline: bool,
};

pub const TerminalScreen = struct {
    allocator: std.mem.Allocator,
    rows: usize,
    cols: usize,
    cells: []TerminalCell,
    cursor_x: usize,
    cursor_y: usize,

    pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !TerminalScreen {
        const cells = try allocator.alloc(TerminalCell, rows * cols);
        @memset(cells, .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false });
        return TerminalScreen{ .allocator = allocator, .rows = rows, .cols = cols, .cells = cells, .cursor_x = 0, .cursor_y = 0 };
    }

    pub fn deinit(self: *TerminalScreen) void {
        self.allocator.free(self.cells);
    }

    pub fn resize(self: *TerminalScreen, rows: usize, cols: usize) !void {
        self.allocator.free(self.cells);
        self.rows = rows;
        self.cols = cols;
        self.cells = try self.allocator.alloc(TerminalCell, rows * cols);
        @memset(self.cells, .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false });
    }

    pub fn setCell(self: *TerminalScreen, x: usize, y: usize, cell: TerminalCell) void {
        if (x < self.cols and y < self.rows) {
            self.cells[y * self.cols + x] = cell;
        }
    }

    pub fn getCell(self: *const TerminalScreen, x: usize, y: usize) TerminalCell {
        if (x < self.cols and y < self.rows) return self.cells[y * self.cols + x];
        return .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false };
    }

    pub fn scroll(self: *TerminalScreen) !void {
        if (self.rows > 1) {
            const cells_to_move = (self.rows - 1) * self.cols;
            @memcpy(self.cells[0..cells_to_move], self.cells[self.cols .. self.cols + cells_to_move]);
            @memset(self.cells[self.cells.len - self.cols ..], .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false });
        }
    }

    pub fn clear(self: *TerminalScreen) void {
        @memset(self.cells, .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false });
        self.cursor_x = 0;
        self.cursor_y = 0;
    }

    pub fn clearLine(self: *TerminalScreen, y: usize) void {
        if (y < self.rows) {
            @memset(self.cells[y * self.cols .. (y + 1) * self.cols], .{ .char = ' ', .fg = 0xFFFFFF, .bg = 0x000000, .bold = false, .italic = false, .underline = false });
        }
    }
};

pub const Terminal = struct {
    allocator: std.mem.Allocator,
    screen: TerminalScreen,
    title: []const u8,

    pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Terminal {
        return Terminal{
            .allocator = allocator,
            .screen = try TerminalScreen.init(allocator, rows, cols),
            .title = "终端",
        };
    }

    pub fn deinit(self: *Terminal) void {
        self.screen.deinit();
    }

    pub fn write(self: *Terminal, data: []const u8) !void {
        for (data) |byte| try self.writeByte(byte);
    }

    fn writeByte(self: *Terminal, byte: u8) !void {
        switch (byte) {
            '\n' => {
                self.screen.cursor_y += 1;
                if (self.screen.cursor_y >= self.screen.rows) {
                    try self.screen.scroll();
                    self.screen.cursor_y = self.screen.rows - 1;
                }
            },
            '\r' => self.screen.cursor_x = 0,
            '\t' => {
                self.screen.cursor_x = (self.screen.cursor_x / 8 + 1) * 8;
                if (self.screen.cursor_x >= self.screen.cols) self.screen.cursor_x = self.screen.cols - 1;
            },
            0x08 => {
                if (self.screen.cursor_x > 0) self.screen.cursor_x -= 1;
            },
            else => {
                self.screen.setCell(self.screen.cursor_x, self.screen.cursor_y, .{
                    .char = byte, .fg = 0xFFFFFF, .bg = 0x000000,
                    .bold = false, .italic = false, .underline = false,
                });
                self.screen.cursor_x += 1;
                if (self.screen.cursor_x >= self.screen.cols) {
                    self.screen.cursor_x = 0;
                    self.screen.cursor_y += 1;
                    if (self.screen.cursor_y >= self.screen.rows) {
                        try self.screen.scroll();
                        self.screen.cursor_y = self.screen.rows - 1;
                    }
                }
            },
        }
    }

    pub fn resize(self: *Terminal, rows: usize, cols: usize) !void {
        try self.screen.resize(rows, cols);
    }
};
