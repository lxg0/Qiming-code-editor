const std = @import("std");

pub const Peer = struct {
    id: u64,
    name: []const u8,
    is_connected: bool,
    latency_ms: u32,

    pub fn init(id: u64, name: []const u8) Peer {
        return Peer{ .id = id, .name = name, .is_connected = false, .latency_ms = 0 };
    }

    pub fn send(self: *const Peer, data: []const u8) !void {
        _ = self; _ = data;
    }

    pub fn receive(self: *const Peer) ![]u8 {
        _ = self;
        return &[_]u8{};
    }
};
