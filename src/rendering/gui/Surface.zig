const std = @import("std");
const Color = @import("../Theme.zig").Color;

pub const Surface = struct {
    width: u32,
    height: u32,
    scale: f32,
    pixels: []Color,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Surface {
        return Surface{
            .width = width,
            .height = height,
            .scale = 1.0,
            .pixels = try allocator.alloc(Color, width * height),
        };
    }

    pub fn deinit(self: *Surface, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    pub fn clear(self: *Surface, color: Color) void {
        @memset(self.pixels, color);
    }

    pub fn setPixel(self: *Surface, x: u32, y: u32, color: Color) void {
        if (x < self.width and y < self.height) {
            self.pixels[y * self.width + x] = color;
        }
    }

    pub fn getPixel(self: *const Surface, x: u32, y: u32) Color {
        if (x < self.width and y < self.height) {
            return self.pixels[y * self.width + x];
        }
        return Color.Transparent;
    }

    pub fn fillRect(self: *Surface, x: u32, y: u32, w: u32, h: u32, color: Color) void {
        const x_end = @min(x + w, self.width);
        const y_end = @min(y + h, self.height);
        var py = y;
        while (py < y_end) : (py += 1) {
            @memset(self.pixels[py * self.width + x .. py * self.width + x_end], color);
        }
    }
};
