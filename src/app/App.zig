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
const Highlighter = @import("../syntax/Highlight.zig").Highlighter;
const TokenType = @import("../syntax/Syntax.zig").TokenType;
const Color = @import("../rendering/Theme.zig").Color;

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
    highlighter: Highlighter,
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
            .highlighter = Highlighter.init(allocator),
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
        self.highlighter.deinit();
        self.notifications.deinit();
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
        const Input = @import("../input/Input.zig").InputReader;
        var tui = TuiRenderer.init(self.allocator);
        defer tui.deinit();
        var input = Input.init(self.allocator);
        defer input.deinit();

        // Detect TTY: attempt tcgetattr on stdin
        const orig_termios = std.posix.tcgetattr(0) catch |e| {
            // Not a terminal (e.g. piped input), print banner and exit
            std.debug.print("[启明] 非终端环境，退出。错误: {any}\n", .{e});
            return;
        };
        _ = orig_termios;

        try tui.enableAltScreen();
        defer tui.disableAltScreen() catch {};
        try tui.enableRawMode();
        defer tui.disableRawMode() catch {};

        // Detect terminal size
        const sz = try tui.getSize();
        tui.setSize(sz.width, sz.height);

        self.running = true;
        while (self.running) {
            // ── Render ──────────────────────────────────────────────────────
            try tui.clear();
            try self.renderTuiFrame(&tui);
            try tui.flush();

            // ── Input ───────────────────────────────────────────────────────
            const event = input.readEvent() catch |e| switch (e) {
                error.EndOfStream => break,
                else => return e,
            };
            try self.handleTuiEvent(event);
        }
    }

    fn renderTuiFrame(self: *App, tui: anytype) !void {
        const doc = self.editor.activeDocument();
        const view = self.editor.activeView();
        const theme = tui.theme;
        const sz = try tui.getSize();

        // ── Status bar ──────────────────────────────────────────────────────
        const status_y = sz.height -| 1;
        const lc = doc.lineCount();
        const cursor_pos = view.primaryCursor().position;
        const coord = doc.buffer.positionToLineCol(cursor_pos);
        const status = try std.fmt.allocPrint(self.allocator,
            " 启明编辑器  {s}  行 {d}/{d}  列 {d}  {s} ",
            .{ doc.fileName(), coord.line + 1, lc, coord.col + 1, doc.language }
        );
        defer self.allocator.free(status);
        try tui.drawText(status, 0, status_y, theme.statusbar_foreground, theme.statusbar_background);

        // ── Tab bar ─────────────────────────────────────────────────────────
        const tab_y = 0;
        for (self.editor.documents.items, 0..) |d, idx| {
            const marker = if (d.is_dirty) "● " else "  ";
            const label = try std.fmt.allocPrint(self.allocator, "{s}{s} ", .{ marker, d.fileName() });
            defer self.allocator.free(label);
            const is_active = idx == self.editor.active_document_index;
            const fg = if (is_active) theme.tab_active_foreground else theme.tab_inactive_foreground;
            const bg = if (is_active) theme.tab_active_background else theme.tab_inactive_background;
            const col: usize = idx * 18;
            try tui.drawText(label, col, tab_y, fg, bg);
        }

        // ── Editor area ─────────────────────────────────────────────────────
        const line_area_start: usize = 1;
        const line_area_end: usize = status_y;
        const visible = view.getVisibleLineRange();
        const gutter_width: usize = 5;

        var row: usize = line_area_start;
        var line_num: usize = visible.start;
        while (row < line_area_end) : ({ row += 1; line_num += 1; }) {
            const line_text = doc.buffer.getLine(line_num) catch break;
            defer self.allocator.free(line_text);

            // Gutter line number
            const gutter = try std.fmt.allocPrint(self.allocator, "{d:>4} ", .{line_num + 1});
            defer self.allocator.free(gutter);
            try tui.drawText(gutter, 0, row, theme.gutter_foreground, theme.gutter_background);

            // Text with syntax highlight
            var hl = try self.highlighter.highlightLine(line_text, line_num);
            defer hl.deinit();

            for (hl.tokens.items) |tok| {
                const tok_text = line_text[@min(tok.start, line_text.len)..@min(tok.end, line_text.len)];
                if (tok_text.len == 0) continue;
                const fg = tokenColor(tok.type, &theme);
                try tui.drawText(tok_text, gutter_width + tok.start, row, fg, theme.background);
            }

            // Cursor on this line
            if (line_num == coord.line) {
                try tui.setCursorPos(gutter_width + coord.col, row);
                try tui.setCursorVisible(true);
            }
        }
    }

    fn handleTuiEvent(self: *App, event: @import("../input/Input.zig").Event) !void {
        const doc = self.editor.activeDocument();
        const view = self.editor.activeView();
        _ = view;
        switch (event) {
            .key => |ke| {
                const mods = ke.modifiers;
                switch (ke.key) {
                    .char => |c| {
                        if (mods.ctrl) {
                            switch (c) {
                                'q' => self.running = false,
                                's' => try self.editor.saveFile(null),
                                'z' => try self.editor.undo(),
                                'y' => try self.editor.redo(),
                                else => {},
                            }
                        } else if (!mods.alt) {
                            // Regular character: encode codepoint to UTF-8
                            var buf: [4]u8 = undefined;
                            const len = std.unicode.utf8Encode(c, &buf) catch 0;
                            if (len > 0) try self.editor.insertAtCursor(buf[0..len]);
                        }
                    },
                    .backspace => try self.editor.deleteAtCursor(.left),
                    .delete    => try self.editor.deleteAtCursor(.right),
                    .enter => try self.editor.insertAtCursor("\n"),
                    .tab   => try self.editor.insertAtCursor("    "),
                    .arrow_left  => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        if (cur.position > 0) cur.setPosition(cur.position - 1);
                    },
                    .arrow_right => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        if (cur.position < doc.buffer.len()) cur.setPosition(cur.position + 1);
                    },
                    .arrow_up => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        const pos  = cur.position;
                        const ls   = doc.buffer.lineStart(pos);
                        if (ls == 0) {
                            cur.setPosition(0);
                        } else {
                            const pls  = doc.buffer.lineStart(ls -| 1);
                            const col  = pos - ls;
                            const plen = (ls - 1) - pls;
                            cur.setPosition(pls + @min(col, plen));
                        }
                    },
                    .arrow_down => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        const pos  = cur.position;
                        const le   = doc.buffer.lineEnd(pos);
                        if (le < doc.buffer.len()) {
                            const nls  = le + 1;
                            const nle  = doc.buffer.lineEnd(nls);
                            const col  = pos - doc.buffer.lineStart(pos);
                            const nlen = nle - nls;
                            cur.setPosition(nls + @min(col, nlen));
                        }
                    },
                    .home => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        cur.setPosition(doc.buffer.lineStart(cur.position));
                    },
                    .end  => {
                        const cur = self.editor.activeView().primaryCursorMut();
                        cur.setPosition(doc.buffer.lineEnd(cur.position));
                    },
                    .page_up   => {
                        const cur   = self.editor.activeView().primaryCursorMut();
                        const range = self.editor.activeView().getVisibleLineRange();
                        const lines = range.end - range.start;
                        var j: usize = 0;
                        while (j < lines and cur.position > 0) : (j += 1) {
                            const ls = doc.buffer.lineStart(cur.position -| 1);
                            cur.setPosition(if (ls == 0) 0 else doc.buffer.lineStart(ls -| 1));
                        }
                    },
                    .page_down => {
                        const cur   = self.editor.activeView().primaryCursorMut();
                        const range = self.editor.activeView().getVisibleLineRange();
                        const lines = range.end - range.start;
                        var j: usize = 0;
                        while (j < lines and cur.position < doc.buffer.len()) : (j += 1) {
                            const le = doc.buffer.lineEnd(cur.position);
                            cur.setPosition(@min(le + 1, doc.buffer.len()));
                        }
                    },
                    else => {},
                }
            },
            .resize => |r| {
                // Terminal resize
                _ = r;
            },
            else => {},
        }
    }

    fn runGui(self: *App) !void {
        const platform = @import("../platform/mod.zig");
        if (!platform.isMacOS()) {
            self.log.info("[GUI] 当前平台不支持GUI模式，已切换至TUI模式", .{});
            try self.runTui();
            return;
        }

        const Bridge = platform.macos.Bridge;
        const NativeWindow = platform.macos.Window;

        self.log.info("[GUI] 初始化 macOS 窗口", .{});

        var window = try NativeWindow.init(self.allocator, .{
            .title = "Qiming Editor - 启明编辑器",
            .width = 1200,
            .height = 800,
        });
        defer window.deinit();

        try window.open();
        self.log.info("[GUI] 窗口已打开，进入事件循环", .{});

        self.running = true;
        while (self.running) {
            // ── pump NSApplication events ──
            _ = Bridge.qiming_macos_pump_events();

            // ── drain bridge event queue ──
            while (window.renderer.pollEvent()) |ev| {
                try self.handleGuiEvent(ev, &window);
            }

            // ── check window close ──
            if (Bridge.qiming_macos_window_should_close(window.native_handle) != 0) {
                self.running = false;
                break;
            }

            // ── render ──
            if (window.beginFrame()) {
                try self.renderEditorFrame(&window);
                window.endFrame();
            }
        }

        self.log.info("[GUI] 事件循环退出", .{});
    }

    fn handleGuiEvent(self: *App, ev: @import("../platform/macos/Bridge.zig").Event, window: anytype) !void {
        const Bridge = @import("../platform/macos/Bridge.zig");
        switch (ev.type) {
            Bridge.EVENT_CLOSE => self.running = false,

            Bridge.EVENT_RESIZE => {
                const w: u32 = @intCast(@max(ev.width,  1));
                const h: u32 = @intCast(@max(ev.height, 1));
                window.handleResize(w, h);
            },

            Bridge.EVENT_KEY => {
                // ev.text contains the UTF-8 character(s)
                const txt = std.mem.sliceTo(&ev.text, 0);
                const mods = ev.modifiers;
                const ctrl_cmd = (mods & 0x100000) != 0 or (mods & 0x000008) != 0; // NSEventModifierFlagCommand | Control

                if (ctrl_cmd) {
                    // macOS uses Cmd for most shortcuts
                    if (txt.len > 0) {
                        switch (txt[0]) {
                            'q', 'Q' => self.running = false,
                            's', 'S' => try self.editor.saveFile(null),
                            'z', 'Z' => try self.editor.undo(),
                            'y', 'Y' => try self.editor.redo(),
                            else => {},
                        }
                    }
                } else if (txt.len > 0 and txt[0] >= 0x20) {
                    // Printable character input
                    try self.editor.insertAtCursor(txt);
                    self.editor.activeView().scrollToCursor();
                } else {
                    // Special keys by keycode (macOS Virtual Key codes)
                    switch (ev.keycode) {
                        0x33 => try self.editor.deleteAtCursor(.left),   // Backspace
                        0x75 => try self.editor.deleteAtCursor(.right),  // Delete
                        0x24, 0x4C => try self.editor.insertAtCursor("\n"), // Return / numpad Enter
                        0x30 => try self.editor.insertAtCursor("    "),   // Tab
                        // Arrow keys
                        0x7B => {
                            const cur = self.editor.activeView().primaryCursorMut();
                            if (cur.position > 0) cur.setPosition(cur.position - 1);
                        },
                        0x7C => {
                            const cur = self.editor.activeView().primaryCursorMut();
                            const doc = self.editor.activeDocument();
                            if (cur.position < doc.buffer.len()) cur.setPosition(cur.position + 1);
                        },
                        0x7E => { // Up
                            const doc = self.editor.activeDocument();
                            const cur = self.editor.activeView().primaryCursorMut();
                            const ls  = doc.buffer.lineStart(cur.position);
                            if (ls > 0) {
                                const pls = doc.buffer.lineStart(ls -| 1);
                                const col = cur.position - ls;
                                cur.setPosition(pls + @min(col, (ls - 1) - pls));
                            }
                        },
                        0x7D => { // Down
                            const doc = self.editor.activeDocument();
                            const cur = self.editor.activeView().primaryCursorMut();
                            const le  = doc.buffer.lineEnd(cur.position);
                            if (le < doc.buffer.len()) {
                                const col = cur.position - doc.buffer.lineStart(cur.position);
                                const nle = doc.buffer.lineEnd(le + 1);
                                cur.setPosition((le + 1) + @min(col, nle - (le + 1)));
                            }
                        },
                        0x73 => { // Home
                            const doc = self.editor.activeDocument();
                            const cur = self.editor.activeView().primaryCursorMut();
                            cur.setPosition(doc.buffer.lineStart(cur.position));
                        },
                        0x77 => { // End
                            const doc = self.editor.activeDocument();
                            const cur = self.editor.activeView().primaryCursorMut();
                            cur.setPosition(doc.buffer.lineEnd(cur.position));
                        },
                        else => {},
                    }
                    self.editor.activeView().scrollToCursor();
                }
            },

            Bridge.EVENT_MOUSE_DOWN => {
                // Click to position cursor
                const view = self.editor.activeView();
                const pos  = view.coordsToPosition(ev.mouse_x, ev.mouse_y - 30.0); // -30 = tab bar height
                view.primaryCursorMut().setPosition(pos);
            },

            else => {},
        }
    }

    fn renderEditorFrame(self: *App, window: anytype) !void {
        const renderer = &window.renderer;
        const theme    = renderer.theme;
        const W: f32   = @floatFromInt(window.width);
        const H: f32   = @floatFromInt(window.height);
        const doc      = self.editor.activeDocument();
        const view     = self.editor.activeView();
        const font_sz  : f32 = 14.0;
        const line_h   : f32 = font_sz * 1.5;
        const gutter_w : f32 = 52.0;
        const tab_h    : f32 = 30.0;
        const status_h : f32 = 22.0;
        const editor_y0: f32 = tab_h;
        const editor_y1: f32 = H - status_h;

        // ── Tab bar background ────────────────────────────────────────────────
        renderer.drawRect(0, 0, W, tab_h, theme.panel_background);
        var tab_x: f32 = 0;
        for (self.editor.documents.items, 0..) |d, idx| {
            const is_active = idx == self.editor.active_document_index;
            const bg = if (is_active) theme.tab_active_background else theme.tab_inactive_background;
            const fg = if (is_active) theme.tab_active_foreground else theme.tab_inactive_foreground;
            renderer.drawRect(tab_x, 0, 150, tab_h, bg);
            // Active tab indicator bar
            if (is_active) renderer.drawRect(tab_x, 0, 150, 2, theme.caret);
            const dirty_mark = if (d.is_dirty) "● " else "";
            const label = try std.fmt.allocPrintSentinel(self.allocator, " {s}{s} ", .{ dirty_mark, d.fileName() }, 0);
            defer self.allocator.free(label);
            renderer.drawText(label, tab_x + 8, tab_h - font_sz - 4, fg, font_sz);
            tab_x += 150;
        }

        // ── Editor background ─────────────────────────────────────────────────
        renderer.drawRect(0, editor_y0, W, editor_y1 - editor_y0, theme.background);

        // ── Gutter ────────────────────────────────────────────────────────────
        renderer.drawRect(0, editor_y0, gutter_w, editor_y1 - editor_y0, theme.gutter_background);

        // ── Visible lines ─────────────────────────────────────────────────────
        const visible   = view.getVisibleLineRange();
        const cur_pos   = view.primaryCursor().position;
        const cur_coord = doc.buffer.positionToLineCol(cur_pos);

        // Highlight current line
        const cur_line_y = editor_y0 + @as(f32, @floatFromInt(cur_coord.line - visible.start)) * line_h;
        if (cur_coord.line >= visible.start and cur_coord.line < visible.end) {
            renderer.drawRect(gutter_w, cur_line_y, W - gutter_w, line_h, theme.line_highlight);
        }

        var line_idx: usize = visible.start;
        var screen_y: f32   = editor_y0 + 2;
        while (line_idx < visible.end and screen_y < editor_y1) : ({
            line_idx += 1;
            screen_y += line_h;
        }) {
            // Gutter line number
            const line_text = doc.buffer.getLine(line_idx) catch break;
            defer self.allocator.free(line_text);

            const is_cur = (line_idx == cur_coord.line);
            const gutter_fg = if (is_cur) theme.gutter_active_foreground else theme.gutter_foreground;
            const gnum = try std.fmt.allocPrintSentinel(self.allocator, "{d}", .{line_idx + 1}, 0);
            defer self.allocator.free(gnum);
            renderer.drawText(gnum, 4, screen_y, gutter_fg, font_sz);

            // Syntax-highlighted text
            var hl = try self.highlighter.highlightLine(line_text, line_idx);
            defer hl.deinit();

            for (hl.tokens.items) |tok| {
                const tok_slice = line_text[
                    @min(tok.start, line_text.len)..
                    @min(tok.end,   line_text.len)
                ];
                if (tok_slice.len == 0) continue;
                const tok_z = try self.allocator.dupeZ(u8, tok_slice);
                defer self.allocator.free(tok_z);
                const col = tokenColor(tok.type, &theme);
                const tx  = gutter_w + @as(f32, @floatFromInt(tok.start)) * (font_sz * 0.6);
                renderer.drawText(tok_z, tx, screen_y, col, font_sz);
            }

            // Cursor blinking (draw on current line)
            if (is_cur and (renderer.frame_count / 30) % 2 == 0) {
                const cx = gutter_w + @as(f32, @floatFromInt(cur_coord.col)) * (font_sz * 0.6);
                renderer.drawRect(cx, cur_line_y, 2, line_h, theme.caret);
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
        renderer.drawRect(0, editor_y1, W, status_h, theme.statusbar_background);
        const status = try std.fmt.allocPrintSentinel(self.allocator,
            "  {s}   行 {d}/{d}  列 {d}  {s}  {s}",
            .{ doc.fileName(), cur_coord.line + 1, doc.lineCount(),
               cur_coord.col + 1, doc.language, "UTF-8" }
        , 0);
        defer self.allocator.free(status);
        renderer.drawText(status, 4, editor_y1 + 4, theme.statusbar_foreground, font_sz - 1);
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

/// Map token type to TUI foreground color from current theme
fn tokenColor(ttype: TokenType, theme: *const @import("../rendering/Theme.zig").Theme) Color {
    return switch (ttype) {
        .keyword         => theme.syntax.keyword,
        .string          => theme.syntax.string,
        .number          => theme.syntax.number,
        .comment         => theme.syntax.comment,
        .function        => theme.syntax.function,
        .type            => theme.syntax.type,
        .variable        => theme.syntax.variable,
        .constant        => theme.syntax.constant,
        .operator        => theme.syntax.operator,
        .punctuation     => theme.syntax.punctuation,
        .parameter       => theme.syntax.parameter,
        .property        => theme.syntax.property,
        .tag             => theme.syntax.tag,
        .attribute       => theme.syntax.attribute,
        .regex           => theme.syntax.regex,
        .markup_heading  => theme.syntax.markup_heading,
        .markup_link     => theme.syntax.markup_link,
        .markup_list     => theme.syntax.markup_list,
        .markup_inline_code => theme.syntax.markup_inline_code,
        .markup_code_block  => theme.syntax.markup_code_block,
        else             => theme.foreground,
    };
}
