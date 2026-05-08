const std = @import("std");

pub const SidebarItem = struct {
    id: u64,
    label: []const u8,
    icon: []const u8,
    is_directory: bool,
    is_expanded: bool,
    depth: usize,
    children: std.array_list.Managed(SidebarItem),
};

pub const Sidebar = struct {
    allocator: std.mem.Allocator,
    width: f32,
    visible: bool,
    items: std.array_list.Managed(SidebarItem),
    selected_id: ?u64,
    root_path: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator) Sidebar {
        return Sidebar{
            .allocator = allocator,
            .width = 250,
            .visible = true,
            .items = std.array_list.Managed(SidebarItem).init(allocator),
            .selected_id = null,
            .root_path = null,
        };
    }

    pub fn deinit(self: *Sidebar) void {
        self.items.deinit();
        if (self.root_path) |p| self.allocator.free(p);
    }

    pub fn toggle(self: *Sidebar) void {
        self.visible = !self.visible;
    }

    pub fn addItem(self: *Sidebar, label: []const u8, is_directory: bool, depth: usize) !void {
        try self.items.append(.{
            .id = @intCast(@import("../util/Async.zig").timestampMs()),
            .label = label,
            .icon = if (is_directory) "📁" else "📄",
            .is_directory = is_directory,
            .is_expanded = true,
            .depth = depth,
            .children = std.array_list.Managed(SidebarItem).init(self.allocator),
        });
    }

    pub fn clear(self: *Sidebar) void {
        self.items.clearRetainingCapacity();
    }
};
