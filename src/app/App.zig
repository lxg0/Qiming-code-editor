const std = @import("std");
const Editor = @import("../editor/Editor.zig").Editor;
const Config = @import("Config.zig").Config;
const Command = @import("Command.zig").CommandRegistry;
const AiManager = @import("../ai/AiManager.zig").AiManager;
const FileIO = @import("../fs/FileIO.zig").FileIO;
const Workspace = @import("../workspace/Workspace.zig").Workspace;
const Theme = @import("../rendering/Theme.zig").Theme;
const RendererMod = @import("../rendering/Renderer.zig");
const Renderer = RendererMod.Renderer;
pub const RenderMode = RendererMod.RenderMode;
const NotificationManager = @import("../ui/Notification.zig").NotificationManager;
const I18n = @import("../util/i18n.zig").I18n;
const Log = @import("../util/Log.zig").Logger;



pub const App = struct {
    allocator: std.mem.Allocator,
    editor: Editor,
    config: Config,
    commands: Command,
    ai: AiManager,
    file_io: FileIO,
    workspace: Workspace,
    renderer: Renderer,
    notifications: NotificationManager,
    i18n: I18n,
    log: Log,
    render_mode: RenderMode,
    running: bool,

    pub fn init(allocator: std.mem.Allocator, render_mode: RenderMode) !App {
        var app = App{
            .allocator = allocator,
            .editor = try Editor.init(allocator),
            .config = Config.init(allocator),
            .commands = Command.init(allocator),
            .ai = AiManager.init(allocator),
            .file_io = FileIO.init(allocator),
            .workspace = Workspace.init(allocator),
            .renderer = Renderer.init(allocator, if (render_mode == .tui) RenderMode.tui else if (render_mode == .gui) RenderMode.gui else RenderMode.headless),
            .notifications = NotificationManager.init(allocator),
            .i18n = I18n.init(allocator),
            .log = Log.init(allocator),
            .render_mode = render_mode,
            .running = true,
        };
        try app.commands.registerDefaults();
        app.log.info("Qiming Editor v0.1.0 初始化完成", .{});
        app.notifications.info(app.i18n.tr("编辑器启动完成"));
        return app;
    }

    pub fn deinit(self: *App) void {
        self.editor.deinit();
        self.config.deinit();
        self.commands.deinit();
        self.ai.deinit();
        self.file_io.deinit();
        self.workspace.deinit();
        self.log.deinit();
    }

    pub fn run(self: *App) !void {
        self.log.info("编辑器模式: {s}", .{@tagName(self.render_mode)});
        switch (self.render_mode) {
            .tui => try self.runTui(),
            .gui => try self.runGui(),
            .headless => try self.runHeadless(),
        }
    }

    fn runTui(self: *App) !void {
        const TuiRenderer = @import("../rendering/tui/TuiRenderer.zig").TuiRenderer;
        var tui = TuiRenderer.init(self.allocator);
        defer tui.deinit();

        // Check if stdin is a TTY - if not, just show welcome and exit
        const is_tty = blk: {
            _ = std.posix.tcgetattr(0) catch break :blk false;
            break :blk true;
        };
        if (is_tty) {
            tui.enableAltScreen() catch {};
            tui.enableRawMode() catch {};
        }

        try tui.clear();
        try tui.drawText("Qiming Editor - 启明编辑器 v0.1.0", 0, 0, tui.theme.foreground, tui.theme.background);
        try tui.drawText("使用 `qiming --help` 查看帮助信息", 0, 1, tui.theme.foreground, tui.theme.background);
        try tui.flush();

        if (is_tty) {
            while (self.running) {
                try tui.clear();
                try tui.drawText("Qiming Editor - 启明编辑器", 0, 0, tui.theme.foreground, tui.theme.background);
                try tui.drawText("按 Ctrl+Q 退出", 0, 1, tui.theme.foreground, tui.theme.background);
                try tui.drawText("按 Ctrl+S 保存", 0, 2, tui.theme.foreground, tui.theme.background);
                try tui.drawText("按 Ctrl+O 打开文件", 0, 3, tui.theme.foreground, tui.theme.background);
                try tui.flush();
                var buf: [16]u8 = undefined;
                const n = try std.posix.read(0, &buf);
                if (n > 0) {
                    if (buf[0] == 17) self.running = false;
                    if (n >= 2 and buf[0] == 0x1b and buf[1] == 'q') self.running = false;
                }
            }
        }

        if (is_tty) {
            tui.disableRawMode() catch {};
            tui.disableAltScreen() catch {};
        }
    }

    fn runGui(self: *App) !void {
        _ = self;
        std.debug.print("GUI 模式尚未实现\n", .{});
    }

    fn runHeadless(self: *App) !void {
        _ = self;
        std.debug.print("Headless 模式 - 等待连接...\n", .{});
    }

    pub fn openFile(self: *App, path: []const u8) !void {
        try self.editor.openFile(path);
        try self.workspace.addOpenFile(path);
        self.notifications.info(try std.fmt.allocPrint(self.allocator, "已打开: {s}", .{path}));
    }

    pub fn saveFile(self: *App, path: ?[]const u8) !void {
        try self.editor.saveFile(path);
        self.notifications.success("文件已保存");
    }

    pub fn quit(self: *App) void {
        self.running = false;
    }
};
