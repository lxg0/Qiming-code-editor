const std = @import("std");

pub const FoldRegion = struct {
    start_line: usize,
    end_line: usize,
    folded: bool,
};

pub const FoldingEngine = struct {
    allocator: std.mem.Allocator,
    regions: std.array_list.Managed(FoldRegion),

    pub fn init(allocator: std.mem.Allocator) FoldingEngine {
        return FoldingEngine{ .allocator = allocator, .regions = std.array_list.Managed(FoldRegion).init(allocator) };
    }

    pub fn deinit(self: *FoldingEngine) void {
        self.regions.deinit();
    }

    pub fn analyzeLine(self: *FoldingEngine, line: []const u8, line_num: usize) void {
        var i: usize = 0;
        while (i < line.len) {
            if (std.mem.startsWith(u8, line[i..], "//")) break;
            if (line[i] == '"') {
                i += 1;
                while (i < line.len and line[i] != '"') {
                    if (line[i] == '\\') i += 2 else i += 1;
                }
                i += 1;
                continue;
            }
            if (line[i] == '{') {
                self.regions.append(.{ .start_line = line_num, .end_line = line_num, .folded = false }) catch {};
            }
            if (line[i] == '}') {
                for (self.regions.items) |*region| {
                    if (region.end_line == region.start_line) {
                        region.end_line = line_num;
                        break;
                    }
                }
            }
            i += 1;
        }
    }

    pub fn clear(self: *FoldingEngine) void {
        self.regions.clearRetainingCapacity();
    }

    pub fn toggleFold(self: *FoldingEngine, line: usize) void {
        for (&self.regions.items) |*region| {
            if (region.start_line == line) {
                region.folded = !region.folded;
                return;
            }
        }
    }
};
