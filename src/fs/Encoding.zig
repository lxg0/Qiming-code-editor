const std = @import("std");

pub const Encoding = enum {
    utf8,
    gbk,
    big5,
    shift_jis,
    euc_kr,
    iso_8859_1,
    windows_1252,
    unknown,
};

pub const EncodingDetector = struct {
    pub fn detect(content: []const u8) Encoding {
        if (content.len >= 3 and content[0] == 0xEF and content[1] == 0xBB and content[2] == 0xBF) return .utf8;
        if (content.len >= 2 and content[0] == 0xFE and content[1] == 0xFF) return .utf8;
        if (content.len >= 2 and content[0] == 0xFF and content[1] == 0xFE) return .utf8;
        if (std.unicode.utf8Validate(content)) return .utf8;
        if (hasGbkBytes(content)) return .gbk;
        return .unknown;
    }

    fn hasGbkBytes(content: []const u8) bool {
        var gbk_count: usize = 0;
        var i: usize = 0;
        while (i + 1 < content.len) : (i += 2) {
            const first = content[i];
            const second = content[i + 1];
            if (first >= 0x81 and first <= 0xFE and second >= 0x40 and second <= 0xFE) {
                gbk_count += 1;
            }
        }
        return gbk_count > content.len / 20;
    }

    pub fn toUtf8(content: []const u8, encoding: Encoding, allocator: std.mem.Allocator) ![]u8 {
        _ = allocator;
        if (encoding == .utf8) {
            if (content.len >= 3 and content[0] == 0xEF and content[1] == 0xBB and content[2] == 0xBF) {
                return try allocator.dupe(u8, content[3..]);
            }
            return try allocator.dupe(u8, content);
        }
        return error.EncodingNotSupported;
    }

    pub fn name(encoding: Encoding) []const u8 {
        return switch (encoding) {
            .utf8 => "UTF-8",
            .gbk => "GBK",
            .big5 => "Big5",
            .shift_jis => "Shift JIS",
            .euc_kr => "EUC-KR",
            .iso_8859_1 => "ISO-8859-1",
            .windows_1252 => "Windows-1252",
            .unknown => "UTF-8",
        };
    }
};
