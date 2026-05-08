const std = @import("std");

pub const TreeNode = struct {
    name: []const u8,
    path: []const u8,
    is_directory: bool,
    is_expanded: bool,
    depth: usize,
    children: std.array_list.Managed(TreeNode),
};

pub const ProjectTree = struct {
    allocator: std.mem.Allocator,
    root: ?TreeNode,
    need_refresh: bool,

    pub fn init(allocator: std.mem.Allocator) ProjectTree {
        return ProjectTree{ .allocator = allocator, .root = null, .need_refresh = true };
    }

    pub fn deinit(self: *ProjectTree) void {
        _ = self;
    }

    pub fn scanDirectory(self: *ProjectTree, path: []const u8) !void {
        _ = self; _ = path;
        self.need_refresh = false;
    }

    pub fn toggleExpand(self: *ProjectTree, path: []const u8) void {
        _ = self; _ = path;
    }
};
