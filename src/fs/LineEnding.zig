pub const LineEnding = enum {
    lf,
    crlf,
    cr,
    mixed,
};

pub const LineEndingHelper = struct {
    pub fn detect(content: []const u8) LineEnding {
        var crlf_count: usize = 0;
        var lf_count: usize = 0;
        var cr_count: usize = 0;
        var i: usize = 0;
        while (i < content.len) {
            if (content[i] == '\r') {
                if (i + 1 < content.len and content[i + 1] == '\n') {
                    crlf_count += 1;
                    i += 2;
                } else {
                    cr_count += 1;
                    i += 1;
                }
            } else if (content[i] == '\n') {
                lf_count += 1;
                i += 1;
            } else {
                i += 1;
            }
        }
        if (crlf_count > 0 and lf_count == 0 and cr_count == 0) return .crlf;
        if (cr_count > 0 and lf_count == 0 and crlf_count == 0) return .cr;
        if (crlf_count > 0 and (lf_count > 0 or cr_count > 0)) return .mixed;
        return .lf;
    }

    pub fn normalize(content: []const u8, target: LineEnding, allocator: std.mem.Allocator) ![]u8 {
        _ = allocator;
        if (target == .lf) {
            var result = std.array_list.Managed(u8).init(allocator);
            var i: usize = 0;
            while (i < content.len) {
                if (content[i] == '\r') {
                    try result.append('\n');
                    if (i + 1 < content.len and content[i + 1] == '\n') i += 2;
                    else i += 1;
                } else {
                    try result.append(content[i]);
                    i += 1;
                }
            }
            return result.items;
        }
        return try allocator.dupe(u8, content);
    }
};
