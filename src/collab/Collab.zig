const std = @import("std");
const Crdt = @import("Crdt.zig").CrdtEngine;

pub const CollabSession = struct {
    allocator: std.mem.Allocator,
    session_id: []const u8,
    peers: std.array_list.Managed(PeerInfo),
    connected: bool,
    crdt: Crdt,

    pub const PeerInfo = struct {
        id: u64,
        name: []const u8,
        color: u32,
        cursor_line: usize,
        cursor_col: usize,
    };

    pub fn init(allocator: std.mem.Allocator) CollabSession {
        return CollabSession{
            .allocator = allocator,
            .session_id = "",
            .peers = std.array_list.Managed(PeerInfo).init(allocator),
            .connected = false,
            .crdt = Crdt.init(allocator),
        };
    }

    pub fn deinit(self: *CollabSession) void {
        self.peers.deinit();
    }

    pub fn connect(self: *CollabSession, host: []const u8, port: u16) !void {
        _ = self; _ = host; _ = port;
        self.connected = true;
    }

    pub fn disconnect(self: *CollabSession) void {
        self.connected = false;
    }
};
