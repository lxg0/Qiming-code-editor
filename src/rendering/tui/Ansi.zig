pub const Ansi = struct {
    pub const Reset = "\x1b[0m";
    pub const Bold = "\x1b[1m";
    pub const Dim = "\x1b[2m";
    pub const Italic = "\x1b[3m";
    pub const Underline = "\x1b[4m";
    pub const Blink = "\x1b[5m";
    pub const Reverse = "\x1b[7m";
    pub const Hidden = "\x1b[8m";
    pub const Strikethrough = "\x1b[9m";

    pub const CursorHome = "\x1b[H";
    pub const CursorHide = "\x1b[?25l";
    pub const CursorShow = "\x1b[?25h";
    pub const ClearScreen = "\x1b[2J";
    pub const ClearLine = "\x1b[K";
    pub const ClearToEnd = "\x1b[0K";
    pub const ClearToStart = "\x1b[1K";

    pub const AltScreenEnter = "\x1b[?1049h";
    pub const AltScreenExit = "\x1b[?1049l";

    pub const SgrFg = struct {
        pub const Black = "\x1b[30m";
        pub const Red = "\x1b[31m";
        pub const Green = "\x1b[32m";
        pub const Yellow = "\x1b[33m";
        pub const Blue = "\x1b[34m";
        pub const Magenta = "\x1b[35m";
        pub const Cyan = "\x1b[36m";
        pub const White = "\x1b[37m";
        pub const Default = "\x1b[39m";
    };

    pub const SgrBg = struct {
        pub const Black = "\x1b[40m";
        pub const Red = "\x1b[41m";
        pub const Green = "\x1b[42m";
        pub const Yellow = "\x1b[43m";
        pub const Blue = "\x1b[44m";
        pub const Magenta = "\x1b[45m";
        pub const Cyan = "\x1b[46m";
        pub const White = "\x1b[47m";
        pub const Default = "\x1b[49m";
    };

    pub fn cursorPos(x: usize, y: usize) [32]u8 {
        var buf: [32]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b[{};{}H", .{ y + 1, x + 1 }) catch unreachable;
        return buf;
    }

    pub fn rgbFg(r: u8, g: u8, b: u8) [20]u8 {
        var buf: [20]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b[38;2;{};{};{}m", .{ r, g, b }) catch unreachable;
        return buf;
    }

    pub fn rgbBg(r: u8, g: u8, b: u8) [20]u8 {
        var buf: [20]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b[48;2;{};{};{}m", .{ r, g, b }) catch unreachable;
        return buf;
    }
};
