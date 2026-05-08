const std = @import("std");

pub const Ime = struct {
    allocator: std.mem.Allocator,
    composing: bool,
    composition: std.array_list.Managed(u8),
    cursor_pos: usize,
    candidate_window: struct {
        visible: bool,
        candidates: [][]const u8,
        selected: usize,
        x: f32,
        y: f32,
    },
    enabled: bool,

    pub fn init(allocator: std.mem.Allocator) Ime {
        return Ime{
            .allocator = allocator,
            .composing = false,
            .composition = std.array_list.Managed(u8).init(allocator),
            .cursor_pos = 0,
            .candidate_window = .{
                .visible = false,
                .candidates = &.{},
                .selected = 0,
                .x = 0,
                .y = 0,
            },
            .enabled = true,
        };
    }

    pub fn deinit(self: *Ime) void {
        self.composition.deinit();
    }

    pub fn startComposition(self: *Ime) void {
        self.composing = true;
        self.composition.clearRetainingCapacity();
        self.cursor_pos = 0;
    }

    pub fn updateComposition(self: *Ime, text: []const u8) !void {
        self.composition.clearRetainingCapacity();
        try self.composition.appendSlice(text);
        self.cursor_pos = text.len;
    }

    pub fn endComposition(self: *Ime) ![]const u8 {
        self.composing = false;
        const result = try self.allocator.dupe(u8, self.composition.items);
        self.composition.clearRetainingCapacity();
        return result;
    }

    pub fn cancelComposition(self: *Ime) void {
        self.composing = false;
        self.composition.clearRetainingCapacity();
        self.cursor_pos = 0;
    }

    pub fn compositionText(self: *const Ime) []const u8 {
        return self.composition.items;
    }

    pub fn isComposing(self: *const Ime) bool {
        return self.composing;
    }

    pub fn setCursorPos(self: *Ime, screen_x: f32, screen_y: f32) void {
        self.candidate_window.x = screen_x;
        self.candidate_window.y = screen_y;
    }

    pub fn enable(self: *Ime) void {
        self.enabled = true;
    }

    pub fn disable(self: *Ime) void {
        self.enabled = false;
        if (self.composing) self.cancelComposition();
    }
};
