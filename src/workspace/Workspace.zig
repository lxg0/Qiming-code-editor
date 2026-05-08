const std = @import("std");

pub const Workspace = struct {
    allocator: std.mem.Allocator,
    root_path: ?[]const u8,
    name: []const u8,
    open_files: std.array_list.Managed([]const u8),

    pub fn init(allocator: std.mem.Allocator) Workspace {
        return Workspace{ .allocator = allocator, .root_path = null, .name = "无标题工作区", .open_files = std.array_list.Managed([]const u8).init(allocator) };
    }

    pub fn deinit(self: *Workspace) void {
        if (self.root_path) |p| self.allocator.free(p);
        for (self.open_files.items) |f| self.allocator.free(f);
        self.open_files.deinit();
    }

    pub fn openFolder(self: *Workspace, path: []const u8) !void {
        if (self.root_path) |p| self.allocator.free(p);
        self.root_path = try self.allocator.dupe(u8, path);
        self.name = std.fs.path.basename(path);
    }

    pub fn closeFolder(self: *Workspace) void {
        if (self.root_path) |p| self.allocator.free(p);
        self.root_path = null;
        self.name = "无标题工作区";
    }

    pub fn addOpenFile(self: *Workspace, path: []const u8) !void {
        for (self.open_files.items) |f| if (std.mem.eql(u8, f, path)) return;
        try self.open_files.append(try self.allocator.dupe(u8, path));
    }

    pub fn removeOpenFile(self: *Workspace, path: []const u8) void {
        for (self.open_files.items, 0..) |f, i| {
            if (std.mem.eql(u8, f, path)) {
                self.allocator.free(f);
                _ = self.open_files.orderedRemove(i);
                return;
            }
        }
    }
};
