pub const Kitty = struct {
    pub const Enter = "\x1b_Ga=d\x1b\\";
    pub const Exit = "\x1b_Ga=D\x1b\\";
    pub const BeginTransmission = "\x1b_Ga=q,t=d,f=24,s=1,v=1\x1b\\";
    pub const EndTransmission = "\x1b_Ga=Q\x1b\\";

    pub const Cwd = "\x1b]7;";
    pub const CwdEnd = "\x1b\\";
    pub const Title = "\x1b]2;";
    pub const TitleEnd = "\x1b\\";

    pub const Keyboard = struct {
        pub const Push = "\x1b[>0u";
        pub const Pop = "\x1b[<0u";
    };

    pub fn imageBegin(width: u32, height: u32, format: u8) [64]u8 {
        var buf: [64]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b_Ga=T,f={d},s={d},v={d},m=1\x1b\\", .{ format, width, height }) catch unreachable;
        return buf;
    }
};
