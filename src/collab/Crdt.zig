const std = @import("std");

pub const OpId = struct {
    replica_id: u64,
    seq: u64,
};

pub const CrdtOp = union(enum) {
    insert: struct { id: OpId, position: OpId, text: []const u8 },
    delete: struct { id: OpId, position: OpId, length: usize },
};

pub const CrdtEngine = struct {
    allocator: std.mem.Allocator,
    replica_id: u64,
    sequence: u64,
    ops: std.array_list.Managed(CrdtOp),

    pub fn init(allocator: std.mem.Allocator) CrdtEngine {
        return CrdtEngine{
            .allocator = allocator,
            .replica_id = @intCast(@import("../util/Async.zig").timestampMs()),
            .sequence = 0,
            .ops = std.array_list.Managed(CrdtOp).init(allocator),
        };
    }

    pub fn deinit(self: *CrdtEngine) void {
        self.ops.deinit();
    }

    pub fn generateInsert(self: *CrdtEngine, position: OpId, text: []const u8) CrdtOp {
        defer self.sequence += 1;
        return .{ .insert = .{ .id = .{ .replica_id = self.replica_id, .seq = self.sequence }, .position = position, .text = text } };
    }

    pub fn generateDelete(self: *CrdtEngine, position: OpId, length: usize) CrdtOp {
        defer self.sequence += 1;
        return .{ .delete = .{ .id = .{ .replica_id = self.replica_id, .seq = self.sequence }, .position = position, .length = length } };
    }

    pub fn apply(self: *CrdtEngine, op: CrdtOp) void {
        _ = self; _ = op;
    }

    pub fn merge(self: *CrdtEngine, remote_ops: []const CrdtOp) void {
        for (remote_ops) |op| self.apply(op);
    }
};
