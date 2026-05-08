const std = @import("std");

pub const Transport = struct {
    allocator: std.mem.Allocator,
    process: ?std.process.Child,
    stdin: ?std.fs.File,
    stdout: ?std.fs.File,

    pub fn init(allocator: std.mem.Allocator) Transport {
        return Transport{ .allocator = allocator, .process = null, .stdin = null, .stdout = null };
    }

    pub fn deinit(self: *Transport) void {
        self.stop() catch {};
    }

    pub fn start(self: *Transport, command: []const u8, args: [][]const u8) !void {
        self.process = std.process.Child.init(&.{ command }, self.allocator);
        if (self.process) |*proc| {
            proc.stdin_behavior = .Pipe;
            proc.stdout_behavior = .Pipe;
            try proc.spawn();
            self.stdin = proc.stdin;
            self.stdout = proc.stdout;
        }
    }

    pub fn stop(self: *Transport) !void {
        if (self.process) |*proc| {
            _ = proc.kill() catch {};
            _ = proc.wait() catch {};
        }
    }

    pub fn send(self: *Transport, message: []const u8) !void {
        if (self.stdin) |stdin| {
            const header = try std.fmt.allocPrint(self.allocator, "Content-Length: {d}\r\n\r\n", .{message.len});
            defer self.allocator.free(header);
            try stdin.writeAll(header);
            try stdin.writeAll(message);
        }
    }

    pub fn receive(self: *Transport) ![]u8 {
        if (self.stdout) |stdout| {
            var header: [128]u8 = undefined;
            var header_len: usize = 0;
            while (header_len < header.len) {
                const n = try stdout.read(header[header_len..]);
                if (n == 0) return error.ConnectionClosed;
                header_len += n;
                if (std.mem.indexOf(u8, header[0..header_len], "\r\n\r\n")) |end| {
                    const header_str = header[0..end];
                    const content_length_start = std.mem.indexOf(u8, header_str, "Content-Length: ") orelse return error.MalformedHeader;
                    const num_start = content_length_start + 16;
                    const num_str = std.mem.trim(u8, header_str[num_start..], " \r\n");
                    const content_length = std.fmt.parseInt(usize, num_str, 10) catch return error.InvalidContentLength;
                    const result = try self.allocator.alloc(u8, content_length);
                    var offset: usize = 0;
                    while (offset < content_length) {
                        const n = try stdout.read(result[offset..]);
                        if (n == 0) return error.ConnectionClosed;
                        offset += n;
                    }
                    return result;
                }
            }
        }
        return error.NoConnection;
    }

    pub fn isRunning(self: *const Transport) bool {
        return self.process != null;
    }
};
