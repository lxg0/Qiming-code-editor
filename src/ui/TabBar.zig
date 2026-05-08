const std = @import("std");
const Theme = @import("../rendering/Theme.zig").Theme;
const Color = @import("../rendering/Theme.zig").Color;

pub const Tab = struct {
    id: u64,
    label: []const u8,
    file_path: ?[]const u8,
    is_active: bool,
    is_dirty: bool,
    language: []const u8,
};

pub const TabBar = struct {
    allocator: std.mem.Allocator,
    tabs: std.array_list.Managed(Tab),
    active_tab_id: ?u64,
    height: f32,
    show_close_button: bool,
    tab_width: f32,

    pub fn init(allocator: std.mem.Allocator) TabBar {
        return TabBar{
            .allocator = allocator,
            .tabs = std.array_list.Managed(Tab).init(allocator),
            .active_tab_id = null,
            .height = 35,
            .show_close_button = true,
            .tab_width = 160,
        };
    }

    pub fn deinit(self: *TabBar) void {
        for (self.tabs.items) |tab| {
            self.allocator.free(tab.label);
            if (tab.file_path) |p| self.allocator.free(p);
        }
        self.tabs.deinit();
    }

    pub fn addTab(self: *TabBar, label: []const u8, file_path: ?[]const u8) !u64 {
        const id = @intCast(@import("../util/Async.zig").timestampMs());
        try self.tabs.append(.{
            .id = id,
            .label = try self.allocator.dupe(u8, label),
            .file_path = if (file_path) |p| try self.allocator.dupe(u8, p) else null,
            .is_active = false,
            .is_dirty = false,
            .language = "text",
        });
        self.active_tab_id = id;
        return id;
    }

    pub fn closeTab(self: *TabBar, id: u64) void {
        for (self.tabs.items, 0..) |tab, i| {
            if (tab.id == id) {
                self.allocator.free(tab.label);
                if (tab.file_path) |p| self.allocator.free(p);
                _ = self.tabs.orderedRemove(i);
                if (self.active_tab_id == id) {
                    if (self.tabs.items.len > 0) {
                        self.active_tab_id = self.tabs.items[@min(i, self.tabs.items.len - 1)].id;
                    } else {
                        self.active_tab_id = null;
                    }
                }
                return;
            }
        }
    }

    pub fn setActiveTab(self: *TabBar, id: u64) void {
        self.active_tab_id = id;
    }

    pub fn activeTab(self: *const TabBar) ?Tab {
        const id = self.active_tab_id orelse return null;
        for (self.tabs.items) |tab| if (tab.id == id) return tab;
        return null;
    }

    pub fn markDirty(self: *TabBar, id: u64, dirty: bool) void {
        for (&self.tabs.items) |*tab| if (tab.id == id) tab.is_dirty = dirty;
    }

    pub fn tabCount(self: *const TabBar) usize {
        return self.tabs.items.len;
    }
};
