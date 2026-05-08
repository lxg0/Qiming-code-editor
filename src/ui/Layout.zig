const std = @import("std");

pub const LayoutDirection = enum {
    horizontal,
    vertical,
};

pub const LayoutConstraints = struct {
    min_width: f32,
    min_height: f32,
    max_width: f32,
    max_height: f32,
};

pub const LayoutEngine = struct {
    direction: LayoutDirection,
    spacing: f32,
    padding: struct { left: f32, right: f32, top: f32, bottom: f32 },

    pub fn init(direction: LayoutDirection) LayoutEngine {
        return LayoutEngine{
            .direction = direction,
            .spacing = 4,
            .padding = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
        };
    }

    pub fn layout(self: *const LayoutEngine, children: []const ChildLayout) void {
        var x: f32 = self.padding.left;
        var y: f32 = self.padding.top;
        for (children) |child| {
            switch (self.direction) {
                .horizontal => {
                    child.setPos(x, y);
                    x += child.width + self.spacing;
                },
                .vertical => {
                    child.setPos(x, y);
                    y += child.height + self.spacing;
                },
            }
        }
    }
};

pub const ChildLayout = struct {
    width: f32,
    height: f32,
    setPos: *const fn (f32, f32) void,
};
