const std = @import("std");
const App = @import("app/App.zig").App;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const render_mode: @import("app/App.zig").RenderMode = .tui;
    const file_to_open: ?[]const u8 = null;

    var app = try App.init(allocator, render_mode);
    defer app.deinit();

    if (file_to_open) |path| {
        app.openFile(path) catch |err| {
            std.debug.print("无法打开文件 {s}: {}\n", .{ path, err });
        };
    }

    try app.run();
}
