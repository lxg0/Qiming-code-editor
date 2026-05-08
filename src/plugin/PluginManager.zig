const std = @import("std");
const PluginApi = @import("PluginApi.zig").PluginApi;

pub const Plugin = struct {
    name: []const u8,
    version: []const u8,
    description: []const u8,
    author: []const u8,
    enabled: bool,
};

pub const PluginManager = struct {
    allocator: std.mem.Allocator,
    plugins: std.array_list.Managed(Plugin),
    api: ?*PluginApi,

    pub fn init(allocator: std.mem.Allocator) PluginManager {
        return PluginManager{ .allocator = allocator, .plugins = std.array_list.Managed(Plugin).init(allocator), .api = null };
    }

    pub fn deinit(self: *PluginManager) void {
        self.plugins.deinit();
    }

    pub fn setApi(self: *PluginManager, api: *PluginApi) void {
        self.api = api;
    }

    pub fn loadPlugin(self: *PluginManager, path: []const u8) !void {
        _ = self; _ = path;
    }

    pub fn enablePlugin(self: *PluginManager, name: []const u8) void {
        for (&self.plugins.items) |*p| if (std.mem.eql(u8, p.name, name)) p.enabled = true;
    }

    pub fn disablePlugin(self: *PluginManager, name: []const u8) void {
        for (&self.plugins.items) |*p| if (std.mem.eql(u8, p.name, name)) p.enabled = false;
    }
};
