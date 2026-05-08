const std = @import("std");

pub const PaletteItem = struct {
    label: []const u8,
    description: []const u8,
    action: u64,
    shortcut: ?[]const u8,
    icon: ?[]const u8,
};

pub const CommandPalette = struct {
    allocator: std.mem.Allocator,
    items: std.array_list.Managed(PaletteItem),
    filtered: std.array_list.Managed(usize),
    query: std.array_list.Managed(u8),
    selected_index: usize,
    visible: bool,
    input_active: bool,

    pub fn init(allocator: std.mem.Allocator) CommandPalette {
        return CommandPalette{
            .allocator = allocator,
            .items = std.array_list.Managed(PaletteItem).init(allocator),
            .filtered = std.array_list.Managed(usize).init(allocator),
            .query = std.array_list.Managed(u8).init(allocator),
            .selected_index = 0,
            .visible = false,
            .input_active = false,
        };
    }

    pub fn deinit(self: *CommandPalette) void {
        self.items.deinit();
        self.filtered.deinit();
        self.query.deinit();
    }

    pub fn addItem(self: *CommandPalette, item: PaletteItem) !void {
        try self.items.append(item);
    }

    pub fn toggle(self: *CommandPalette) void {
        self.visible = !self.visible;
        if (self.visible) {
            self.input_active = true;
            self.selected_index = 0;
            self.filter();
        }
    }

    pub fn show(self: *CommandPalette) void {
        self.visible = true;
        self.input_active = true;
        self.selected_index = 0;
        self.filter();
    }

    pub fn hide(self: *CommandPalette) void {
        self.visible = false;
        self.input_active = false;
    }

    pub fn addChar(self: *CommandPalette, c: u8) !void {
        try self.query.append(c);
        self.filter();
    }

    pub fn deleteChar(self: *CommandPalette) void {
        if (self.query.items.len > 0) {
            self.query.items.len -= 1;
            self.filter();
        }
    }

    pub fn selectNext(self: *CommandPalette) void {
        if (self.filtered.items.len > 0) {
            self.selected_index = (self.selected_index + 1) % self.filtered.items.len;
        }
    }

    pub fn selectPrevious(self: *CommandPalette) void {
        if (self.filtered.items.len > 0) {
            self.selected_index = if (self.selected_index == 0)
                self.filtered.items.len - 1
            else
                self.selected_index - 1;
        }
    }

    pub fn selectedItem(self: *const CommandPalette) ?PaletteItem {
        if (self.filtered.items.len == 0) return null;
        return self.items.items[self.filtered.items[self.selected_index]];
    }

    fn filter(self: *CommandPalette) void {
        self.filtered.clearRetainingCapacity();
        const q = self.query.items;
        for (self.items.items, 0..) |item, i| {
            if (q.len == 0 or std.mem.indexOf(u8, item.label, q) != null or
                std.mem.indexOf(u8, item.description, q) != null) {
                self.filtered.append(i) catch {};
            }
        }
        if (self.selected_index >= self.filtered.items.len and self.filtered.items.len > 0) {
            self.selected_index = 0;
        }
    }
};
