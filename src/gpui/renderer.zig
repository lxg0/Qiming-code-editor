const std = @import("std");
const Rect = @import("Rect");

pub const RenderRect = struct {
    rect: Rect,
    color: Rect.Color,
    corner_radius: f32 = 0,
};

pub const RenderText = struct {
    text: []const u8,
    position: Rect.Point,
    color: Rect.Color,
    font_size: f32,
    font_weight: u16 = 400,
};

pub const RenderTriangle = struct {
    p1: Rect.Point,
    p2: Rect.Point,
    p3: Rect.Point,
    color: Rect.Color,
};

pub const RenderPipeline = struct {
    rects: std.array_list.Managed(RenderRect),
    texts: std.array_list.Managed(RenderText),
    triangles: std.array_list.Managed(RenderTriangle),

    pub fn init(allocator: std.mem.Allocator) RenderPipeline {
        return RenderPipeline{
            .rects = std.array_list.Managed(RenderRect).init(allocator),
            .texts = std.array_list.Managed(RenderText).init(allocator),
            .triangles = std.array_list.Managed(RenderTriangle).init(allocator),
        };
    }

    pub fn deinit(self: *RenderPipeline) void {
        self.rects.deinit();
        self.texts.deinit();
        self.triangles.deinit();
    }

    pub fn addRect(self: *RenderPipeline, rect: RenderRect) !void {
        try self.rects.append(rect);
    }

    pub fn addText(self: *RenderPipeline, text: RenderText) !void {
        try self.texts.append(text);
    }

    pub fn addTriangle(self: *RenderPipeline, triangle: RenderTriangle) !void {
        try self.triangles.append(triangle);
    }

    pub fn clear(self: *RenderPipeline) void {
        self.rects.clearRetainingCapacity();
        self.texts.clearRetainingCapacity();
        self.triangles.clearRetainingCapacity();
    }
};

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    scale: f32,
    pipeline: RenderPipeline,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Renderer {
        return Renderer{
            .allocator = allocator,
            .width = width,
            .height = height,
            .scale = 1.0,
            .pipeline = try RenderPipeline.init(allocator),
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.pipeline.deinit();
    }

    pub fn setSize(self: *Renderer, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
    }

    pub fn beginFrame(self: *Renderer) void {
        self.pipeline.clear();
    }

    pub fn drawRect(self: *Renderer, rect: Rect, color: Rect.Color, corner_radius: f32) !void {
        try self.pipeline.addRect(RenderRect{
            .rect = rect,
            .color = color,
            .corner_radius = corner_radius,
        });
    }

    pub fn drawText(self: *Renderer, text: []const u8, position: Rect.Point, color: Rect.Color, font_size: f32) !void {
        try self.pipeline.addText(RenderText{
            .text = text,
            .position = position,
            .color = color,
            .font_size = font_size,
        });
    }

    pub fn endFrame(self: *Renderer) !void {
        _ = self;
    }

    pub fn present(self: *Renderer) !void {
        _ = self;
    }
};
