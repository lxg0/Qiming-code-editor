const std = @import("std");
const dvui = @import("dvui");
const SDLBackend = @import("sdl-backend");

comptime {
    std.debug.assert(@hasDecl(SDLBackend, "SDLBackend"));
}

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

var g_backend: ?SDLBackend = null;
var g_win: ?*dvui.Window = null;

var text_content: std.array_list.Managed(u8) = undefined;

fn gui_frame() bool {
    var keep_running = true;

    {
        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .style = .window, .background = true, .expand = .horizontal, .name = "main" });
        defer hbox.deinit();

        var menu_bar: {
            var m = dvui.menu(@src(), .horizontal, .{});
            defer m.deinit();

            if (dvui.menuItemLabel(@src(), "文件", .{ .submenu = true }, .{})) |r| {
                var fw = dvui.floatingMenu(@src(), .{ .from = r }, .{});
                defer fw.deinit();

                if (dvui.menuItemLabel(@src(), "清空", .{}, .{ .expand = .horizontal })) |_| {
                    text_content.clearRetainingCapacity();
                }

                if (dvui.menuItemLabel(@src(), "退出", .{}, .{ .expand = .horizontal })) |_| {
                    keep_running = false;
                }
            }
        }
    }

    {
        var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroll.deinit();

        var tl = dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font = .theme(.title) });
        tl.addText("Zig 编辑器 - 编辑下方文本", .{});
        tl.deinit();

        var te: dvui.TextEntryWidget = undefined;
        te.init(@src(), .{ 
            .multiline = true, 
            .cache_layout = true,
            .text = .{ .internal = .{ .limit = 1_000_000 } } 
        }, .{ .expand = .both });
        defer te.deinit();

        if (dvui.firstFrame(te.data().id)) {
            te.textSet("在这里输入文本...\n编辑愉快！", false);
        }

        te.processEvents();
        te.draw();
    }

    for (dvui.events()) |*e| {
        if (e.evt == .window and e.evt.window.action == .close) return false;
        if (e.evt == .app and e.evt.app.action == .quit) return false;
    }

    return keep_running;
}

pub fn main() !void {
    defer if (gpa_instance.deinit() != .ok) @panic("Memory leak");

    text_content = std.array_list.Managed(u8).init(gpa);
    defer text_content.deinit();

    var backend = try SDLBackend.initWindow(.{
        .allocator = gpa,
        .size = .{ .w = 800.0, .h = 600.0 },
        .min_size = .{ .w = 400.0, .h = 300.0 },
        .vsync = true,
        .title = "Zig 编辑器",
    });
    g_backend = backend;
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), gpa, backend.backend(), .{
        .theme = switch (backend.preferredColorScheme() orelse .light) {
            .light => dvui.Theme.builtin.adwaita_light,
            .dark => dvui.Theme.builtin.adwaita_dark,
        },
    });
    g_win = &win;
    defer win.deinit();

    var interrupted = false;

    main_loop: while (true) {
        const nstime = win.beginWait(interrupted);

        try win.begin(nstime);
        try backend.addAllEvents(&win);

        _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 0, 0);
        _ = SDLBackend.c.SDL_RenderClear(backend.renderer);

        const keep_running = gui_frame();
        if (!keep_running) break :main_loop;

        const end_micros = try win.end(.{});
        try backend.setCursor(win.cursorRequested());
        try backend.textInputRect(win.textInputRequested());
        try backend.renderPresent();

        const wait_event_micros = win.waitTime(end_micros);
        interrupted = try backend.waitEventTimeout(wait_event_micros);
    }
}
