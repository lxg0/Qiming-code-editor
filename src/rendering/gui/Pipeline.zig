const std = @import("std");
const Color = @import("../Theme.zig").Color;

pub const DrawCommand = union(enum) {
    rect: struct { x: f32, y: f32, w: f32, h: f32, color: Color, radius: f32 },
    text: struct { text: []const u8, x: f32, y: f32, color: Color, size: f32 },
    line: struct { x1: f32, y1: f32, x2: f32, y2: f32, color: Color, width: f32 },
    triangle: struct { x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32, color: Color },
    scissor: struct { x: f32, y: f32, w: f32, h: f32 },
};

pub const RenderPipeline = struct {
    allocator: std.mem.Allocator,
    commands: std.array_list.Managed(DrawCommand),

    pub fn init(allocator: std.mem.Allocator) RenderPipeline {
        return RenderPipeline{
            .allocator = allocator,
            .commands = std.array_list.Managed(DrawCommand).init(allocator),
        };
    }

    pub fn deinit(self: *RenderPipeline) void {
        self.commands.deinit();
    }

    pub fn beginFrame(self: *RenderPipeline) void {
        self.commands.clearRetainingCapacity();
    }

    pub fn drawRect(self: *RenderPipeline, x: f32, y: f32, w: f32, h: f32, color: Color, radius: f32) !void {
        try self.commands.append(.{ .rect = .{ .x = x, .y = y, .w = w, .h = h, .color = color, .radius = radius } });
    }

    pub fn drawText(self: *RenderPipeline, text: []const u8, x: f32, y: f32, color: Color, size: f32) !void {
        try self.commands.append(.{ .text = .{ .text = text, .x = x, .y = y, .color = color, .size = size } });
    }

    pub fn drawLine(self: *RenderPipeline, x1: f32, y1: f32, x2: f32, y2: f32, color: Color, width: f32) !void {
        try self.commands.append(.{ .line = .{ .x1 = x1, .y1 = y1, .x2 = x2, .y2 = y2, .color = color, .width = width } });
    }

    pub fn endFrame(self: *RenderPipeline) void {
        _ = self;
    }
};
