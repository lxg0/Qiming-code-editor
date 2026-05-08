const std = @import("std");

pub const MenuItem = struct {
    id: u64,
    label: []const u8,
    shortcut: ?[]const u8,
    enabled: bool,
    checked: bool,
    separator: bool,
    submenu: ?[]MenuItem,
};

pub const MenuBar = struct {
    allocator: std.mem.Allocator,
    menus: std.array_list.Managed(MenuGroup),
    height: f32,
    active_index: ?usize,

    pub const MenuGroup = struct {
        label: []const u8,
        items: std.array_list.Managed(MenuItem),
    };

    pub fn init(allocator: std.mem.Allocator) !MenuBar {
        var mb = MenuBar{
            .allocator = allocator,
            .menus = std.array_list.Managed(MenuGroup).init(allocator),
            .height = 28,
            .active_index = null,
        };
        try mb.addMenu("文件");
        try mb.addMenu("编辑");
        try mb.addMenu("选择");
        try mb.addMenu("视图");
        try mb.addMenu("转到");
        try mb.addMenu("终端");
        try mb.addMenu("帮助");
        return mb;
    }

    pub fn deinit(self: *MenuBar) void {
        for (self.menus.items) |*group| group.items.deinit();
        self.menus.deinit();
    }

    pub fn addMenu(self: *MenuBar, label: []const u8) !void {
        try self.menus.append(.{
            .label = try self.allocator.dupe(u8, label),
            .items = std.array_list.Managed(MenuItem).init(self.allocator),
        });
    }

    pub fn addItem(self: *MenuBar, menu_idx: usize, label: []const u8, shortcut: ?[]const u8) !void {
        if (menu_idx >= self.menus.items.len) return;
        try self.menus.items[menu_idx].items.append(.{
            .id = @intCast(@import("../util/Async.zig").timestampMs()),
            .label = label,
            .shortcut = shortcut,
            .enabled = true,
            .checked = false,
            .separator = false,
            .submenu = null,
        });
    }

    pub fn addSeparator(self: *MenuBar, menu_idx: usize) !void {
        if (menu_idx >= self.menus.items.len) return;
        try self.menus.items[menu_idx].items.append(.{
            .id = 0,
            .label = "",
            .shortcut = null,
            .enabled = false,
            .checked = false,
            .separator = true,
            .submenu = null,
        });
    }

    pub fn activate(self: *MenuBar, index: ?usize) void {
        self.active_index = index;
    }
};
