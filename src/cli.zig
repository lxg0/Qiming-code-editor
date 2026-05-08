const std = @import("std");
const Buffer = @import("buffer/Buffer.zig").Buffer;
const FileIO = @import("fs/FileIO.zig").FileIO;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var buffer = try Buffer.init(allocator);
    defer buffer.deinit();

    var file_io = try FileIO.init(allocator);
    defer file_io.deinit();

    if (init.minimal.args.vector.len > 1) {
        const file_path = std.mem.span(init.minimal.args.vector[1]);
        try file_io.open(&buffer, file_path);
        const msg = try std.fmt.allocPrint(allocator, "Opened file: {s}\n", .{file_path});
        defer allocator.free(msg);
        try std.Io.File.stdout().writeStreamingAll(io, msg);
    }

    try std.Io.File.stdout().writeStreamingAll(io, "Zig Editor CLI Demo\n");
    try std.Io.File.stdout().writeStreamingAll(io, "===================\n");
    try std.Io.File.stdout().writeStreamingAll(io, "Commands:\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  i <text>   - Insert text at cursor\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  b          - Backspace\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  left/right - Move cursor\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  open <file> - Open file\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  save <file> - Save to file\n");
    try std.Io.File.stdout().writeStreamingAll(io, "  q          - Quit\n");
    try std.Io.File.stdout().writeStreamingAll(io, "===================\n");

    var line_buf = try std.array_list.Managed(u8).initCapacity(allocator, 1024);
    defer line_buf.deinit(allocator);

    while (true) {
        const buf_msg = try std.fmt.allocPrint(allocator, "\nBuffer: {s}\n", .{buffer.data.items});
        defer allocator.free(buf_msg);
        try std.Io.File.stdout().writeStreamingAll(io, buf_msg);

        const cursor_msg = try std.fmt.allocPrint(allocator, "Cursor: {}\n", .{buffer.cursor});
        defer allocator.free(cursor_msg);
        try std.Io.File.stdout().writeStreamingAll(io, cursor_msg);

        try std.Io.File.stdout().writeStreamingAll(io, "> ");
        var flush_buf: [1]u8 = undefined;
        var writer = std.Io.File.stdout().writer(io, &flush_buf);
        try writer.flush();

        line_buf.clearRetainingCapacity();
        var read_buf: [1024]u8 = undefined;
        const n = try std.posix.read(0, &read_buf);
        if (n == 0) break;

        const newline_idx = std.mem.indexOfScalar(u8, read_buf[0..n], '\n') orelse n;
        const line = read_buf[0..newline_idx];

        if (std.mem.eql(u8, line, "q")) break;
        if (std.mem.eql(u8, line, "b")) {
            buffer.backspace();
            continue;
        }
        if (std.mem.eql(u8, line, "left")) {
            if (buffer.cursor > 0) buffer.cursor -= 1;
            continue;
        }
        if (std.mem.eql(u8, line, "right")) {
            if (buffer.cursor < buffer.data.items.len) buffer.cursor += 1;
            continue;
        }

        if (std.mem.startsWith(u8, line, "i ")) {
            try buffer.insert(line[2..]);
            continue;
        }

        if (std.mem.startsWith(u8, line, "open ")) {
            try file_io.open(&buffer, line[5..]);
            const open_msg = try std.fmt.allocPrint(allocator, "Opened file: {s}\n", .{line[5..]});
            defer allocator.free(open_msg);
            try std.Io.File.stdout().writeStreamingAll(io, open_msg);
            continue;
        }

        if (std.mem.startsWith(u8, line, "save ")) {
            try file_io.setCurrentFile(line[5..]);
            try file_io.save(&buffer);
            const save_msg = try std.fmt.allocPrint(allocator, "Saved to {s}\n", .{line[5..]});
            defer allocator.free(save_msg);
            try std.Io.File.stdout().writeStreamingAll(io, save_msg);
            continue;
        }

        const unknown_msg = try std.fmt.allocPrint(allocator, "Unknown command: {s}\n", .{line});
        defer allocator.free(unknown_msg);
        try std.Io.File.stdout().writeStreamingAll(io, unknown_msg);
    }
}
