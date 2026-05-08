const std = @import("std");
const Rect = struct { x: f32, y: f32, w: f32, h: f32 };

pub const Event = union(enum) {
    click: struct { x: f32, y: f32, button: u8 },
    hover: struct { x: f32, y: f32 },
    focus,
    blur,
    key: struct { key: []const u8, ctrl: bool, alt: bool, shift: bool },
    scroll: struct { delta_x: f32, delta_y: f32 },
};

pub const Component = struct {
    id: u64,
    rect: Rect,
    visible: bool,
    enabled: bool,
    focused: bool,
    hovered: bool,
    parent: ?*Component,
    children: std.array_list.Managed(*Component),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Component {
        return Component{
            .id = @intCast(@import("../util/Async.zig").timestampMs()),
            .rect = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
            .visible = true,
            .enabled = true,
            .focused = false,
            .hovered = false,
            .parent = null,
            .children = std.array_list.Managed(*Component).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Component) void {
        for (self.children.items) |child| {
            child.deinit();
            self.allocator.destroy(child);
        }
        self.children.deinit();
    }

    pub fn addChild(self: *Component, child: *Component) !void {
        child.parent = self;
        try self.children.append(child);
    }

    pub fn setRect(self: *Component, rect: Rect) void {
        self.rect = rect;
    }

    pub fn containsPoint(self: *const Component, x: f32, y: f32) bool {
        return self.visible and x >= self.rect.x and x < self.rect.x + self.rect.w and
               y >= self.rect.y and y < self.rect.y + self.rect.h;
    }

    pub fn handleEvent(self: *Component, event: Event) bool {
        _ = self;
        _ = event;
        return false;
    }

    pub fn hitTest(self: *Component, x: f32, y: f32) ?*Component {
        if (!self.visible or !self.containsPoint(x, y)) return null;
        for (self.children.items) |child| {
            if (child.hitTest(x, y)) |hit| return hit;
        }
        return self;
    }
};
