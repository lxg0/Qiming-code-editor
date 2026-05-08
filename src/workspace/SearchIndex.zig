const std = @import("std");

pub const SearchResult = struct {
    file_path: []const u8,
    line: usize,
    column: usize,
    line_content: []const u8,
    match_start: usize,
    match_end: usize,
};

pub const SearchIndex = struct {
    allocator: std.mem.Allocator,
    results: std.array_list.Managed(SearchResult),
    is_indexing: bool,

    pub fn init(allocator: std.mem.Allocator) SearchIndex {
        return SearchIndex{ .allocator = allocator, .results = std.array_list.Managed(SearchResult).init(allocator), .is_indexing = false };
    }

    pub fn deinit(self: *SearchIndex) void {
        self.results.deinit();
    }

    pub fn search(self: *SearchIndex, query: []const u8, paths: []const []const u8, case_sensitive: bool, whole_word: bool, use_regex: bool) !void {
        _ = self; _ = query; _ = paths; _ = case_sensitive; _ = whole_word; _ = use_regex;
    }

    pub fn clear(self: *SearchIndex) void {
        self.results.clearRetainingCapacity();
    }

    pub fn resultCount(self: *const SearchIndex) usize {
        return self.results.items.len;
    }
};
