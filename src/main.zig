const std = @import("std");
const App = @import("app/App.zig").App;
const RenderMode = @import("app/App.zig").RenderMode;

/// Zig 0.16 passes a structured init to main
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // ── Argument parsing ──────────────────────────────────────────────────────
    var render_mode: RenderMode = .tui;
    var file_to_open: ?[]const u8 = null;

    const argv = init.minimal.args.vector;
    var i: usize = 1;
    while (i < argv.len) : (i += 1) {
        const arg = std.mem.span(argv[i]);

        if (std.mem.eql(u8, arg, "--gui") or std.mem.eql(u8, arg, "-g")) {
            render_mode = .gui;
        } else if (std.mem.eql(u8, arg, "--tui") or std.mem.eql(u8, arg, "-t")) {
            render_mode = .tui;
        } else if (std.mem.eql(u8, arg, "--headless") or std.mem.eql(u8, arg, "-H")) {
            render_mode = .headless;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            try printHelp(init.io);
            return;
        } else if (arg.len > 0 and arg[0] != '-') {
            file_to_open = arg;
        }
    }
    // ─────────────────────────────────────────────────────────────────────────

    var app = try App.init(allocator, render_mode);
    defer app.deinit();

    if (file_to_open) |path| {
        app.openFile(path) catch |err| {
            std.debug.print("无法打开文件 {s}: {any}\n", .{ path, err });
        };
    }

    try app.run();
}

fn printHelp(io: std.Io) !void {
    try std.Io.File.stdout().writeStreamingAll(io,
        \\启明编辑器 (Qiming Editor) v0.1.0
        \\用法: qiming [选项] [文件]
        \\
        \\选项:
        \\  --tui, -t       TUI 终端界面模式 [默认]
        \\  --gui, -g       GUI 图形界面模式 (macOS)
        \\  --headless, -H  Headless 无头模式
        \\  --help, -h      显示帮助
        \\
        \\快捷键 (TUI):
        \\  Ctrl+Q          退出
        \\  Ctrl+S          保存
        \\
        \\项目: https://github.com/lxg0/Qiming-code-editor
        \\
    );
}
