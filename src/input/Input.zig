const std = @import("std");

pub const Event = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
    resize: ResizeEvent,
    focus: bool,
    text: []const u8,
};

pub const KeyEvent = struct {
    key: Key,
    modifiers: Modifiers,
    repeated: bool,
};

pub const Key = union(enum) {
    char: u21,
    backspace,
    delete,
    enter,
    tab,
    escape,
    arrow_up,
    arrow_down,
    arrow_left,
    arrow_right,
    home,
    end,
    page_up,
    page_down,
    insert,
    function: u8,
};

pub const Modifiers = struct {
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
    meta: bool = false,

    pub fn none() Modifiers {
        return .{};
    }

    pub fn ctrlOnly() Modifiers {
        return .{ .ctrl = true };
    }

    pub fn isNone(self: *const Modifiers) bool {
        return !self.ctrl and !self.alt and !self.shift and !self.meta;
    }
};

pub const MouseEvent = struct {
    kind: MouseKind,
    button: MouseButton,
    x: usize,
    y: usize,
    modifiers: Modifiers,
};

pub const MouseKind = enum {
    press,
    release,
    drag,
    motion,
    scroll_up,
    scroll_down,
};

pub const MouseButton = enum {
    left,
    right,
    middle,
    none,
};

pub const ResizeEvent = struct {
    width: usize,
    height: usize,
};

pub const InputReader = struct {
    allocator: std.mem.Allocator,
    buf: [64]u8,
    pending: []u8,

    pub fn init(allocator: std.mem.Allocator) InputReader {
        return InputReader{
            .allocator = allocator,
            .buf = undefined,
            .pending = &.{},
        };
    }

    pub fn deinit(self: *InputReader) void {
        _ = self;
    }

    pub fn readEvent(self: *InputReader) !Event {
        var n: usize = 0;
        if (self.pending.len > 0) {
            n = @min(self.pending.len, self.buf.len);
            @memcpy(self.buf[0..n], self.pending[0..n]);
            self.pending = self.pending[n..];
        } else {
            n = try std.posix.read(0, &self.buf);
        }
        if (n == 0) return error.EndOfStream;
        return parseEvent(self.buf[0..n]);
    }

    fn parseEvent(data: []const u8) Event {
        if (data.len == 0) return .{ .key = .{ .key = .{ .char = 0 }, .modifiers = .none(), .repeated = false } };

        // Handle escape sequences
        if (data[0] == 0x1b) {
            if (data.len == 1) return .{ .key = .{ .key = .escape, .modifiers = .none(), .repeated = false } };
            if (data.len >= 2 and data[1] == '[') {
                if (data.len >= 3) {
                    const mod: Modifiers = if (data.len >= 4 and data[data.len - 2] == ';')
                        parseModifier(data[data.len - 1] - '0')
                    else
                        .none();
                    return switch (data[2]) {
                        'A' => makeEvent(.arrow_up, mod),
                        'B' => makeEvent(.arrow_down, mod),
                        'C' => makeEvent(.arrow_right, mod),
                        'D' => makeEvent(.arrow_left, mod),
                        'H' => makeEvent(.home, mod),
                        'F' => makeEvent(.end, mod),
                        '5' => makeEvent(.page_up, mod),
                        '6' => makeEvent(.page_down, mod),
                        '2' => makeEvent(.insert, mod),
                        '3' => makeEvent(.delete, mod),
                        else => makeEvent(.{ .char = data[2] }, mod),
                    };
                }
            }
        }

        // Handle single byte
        const c = data[0];
        if (c == 127 or c == 8) return makeEvent(.backspace, .none());
        if (c == 13) return makeEvent(.enter, .none());
        if (c == 9) return makeEvent(.tab, .none());
        if (c == 27) return makeEvent(.escape, .none());

        // Handle Ctrl+letter
        if (c < 32) {
            const mod = Modifiers{ .ctrl = true };
            const letter = @as(u21, c + 96);
            return switch (letter) {
                's' => makeEvent(.{ .char = 's' }, mod),
                'o' => makeEvent(.{ .char = 'o' }, mod),
                'z' => makeEvent(.{ .char = 'z' }, mod),
                'y' => makeEvent(.{ .char = 'y' }, mod),
                'q' => makeEvent(.{ .char = 'q' }, mod),
                'f' => makeEvent(.{ .char = 'f' }, mod),
                'c' => makeEvent(.{ .char = 'c' }, mod),
                'v' => makeEvent(.{ .char = 'v' }, mod),
                'a' => makeEvent(.{ .char = 'a' }, mod),
                'x' => makeEvent(.{ .char = 'x' }, mod),
                else => makeEvent(.{ .char = letter }, mod),
            };
        }

        // Regular character (could be UTF-8 start byte)
        return makeEvent(.{ .char = c }, .none());
    }

    fn makeEvent(key: Key, modifiers: Modifiers) Event {
        return .{ .key = .{ .key = key, .modifiers = modifiers, .repeated = false } };
    }

    fn parseModifier(val: u8) Modifiers {
        return switch (val) {
            2 => Modifiers{ .shift = true },
            3 => Modifiers{ .alt = true },
            4 => Modifiers{ .alt = true, .shift = true },
            5 => Modifiers{ .ctrl = true },
            6 => Modifiers{ .ctrl = true, .shift = true },
            7 => Modifiers{ .ctrl = true, .alt = true },
            8 => Modifiers{ .meta = true },
            else => .none(),
        };
    }

    pub fn readUtf8Sequence(self: *InputReader, first_byte: u8) ![]u8 {
        _ = self;
        _ = first_byte;
        return &[_]u8{first_byte}; // Simplified
    }
};
