const std = @import("std");

pub const SnippetTabStop = struct {
    index: usize,
    start: usize,
    end: usize,
    placeholder: []const u8,
    choices: [][]const u8,
    is_choice: bool,
};

pub const Snippet = struct {
    allocator: std.mem.Allocator,
    prefix: []const u8,
    body: []const u8,
    description: []const u8,
    tab_stops: std.array_list.Managed(SnippetTabStop),

    pub fn init(allocator: std.mem.Allocator) Snippet {
        return Snippet{
            .allocator = allocator,
            .prefix = "",
            .body = "",
            .description = "",
            .tab_stops = std.array_list.Managed(SnippetTabStop).init(allocator),
        };
    }

    pub fn deinit(self: *Snippet) void {
        self.tab_stops.deinit();
    }

    pub fn parse(self: *Snippet, text: []const u8) !void {
        _ = text;
        // TODO: Parse $1, $2, ${1:placeholder} syntax
    }
};

pub const SnippetManager = struct {
    allocator: std.mem.Allocator,
    snippets: std.StringHashMap(Snippet),

    pub fn init(allocator: std.mem.Allocator) SnippetManager {
        return SnippetManager{
            .allocator = allocator,
            .snippets = std.StringHashMap(Snippet).init(allocator),
        };
    }

    pub fn deinit(self: *SnippetManager) void {
        var it = self.snippets.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.snippets.deinit();
    }

    pub fn register(self: *SnippetManager, language: []const u8, snippet: Snippet) !void {
        try self.snippets.put(language, snippet);
    }

    pub fn get(self: *const SnippetManager, language: []const u8) ?Snippet {
        return self.snippets.get(language);
    }
};
