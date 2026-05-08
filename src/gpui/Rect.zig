pub const Point = struct {
    x: f32,
    y: f32,
};

pub const Size = struct {
    width: f32,
    height: f32,
};

pub const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn zero() Rect {
        return Rect{ .x = 0, .y = 0, .width = 0, .height = 0 };
    }

    pub fn new(x: f32, y: f32, width: f32, height: f32) Rect {
        return Rect{ .x = x, .y = y, .width = width, .height = height };
    }

    pub fn equals(self: Rect, other: Rect) bool {
        return self.x == other.x and
               self.y == other.y and
               self.width == other.width and
               self.height == other.height;
    }

    pub fn containsPoint(self: Rect, point: Point) bool {
        return point.x >= self.x and point.x < self.x + self.width and
               point.y >= self.y and point.y < self.y + self.height;
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return self.x < other.x + other.width and
               self.x + self.width > other.x and
               self.y < other.y + other.height and
               self.y + self.height > other.y;
    }
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn new(r: f32, g: f32, b: f32, a: f32) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{
            .r = @as(f32, @floatFromInt(r)) / 255.0,
            .g = @as(f32, @floatFromInt(g)) / 255.0,
            .b = @as(f32, @floatFromInt(b)) / 255.0,
            .a = 1.0,
        };
    }

    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{
            .r = @as(f32, @floatFromInt(r)) / 255.0,
            .g = @as(f32, @floatFromInt(g)) / 255.0,
            .b = @as(f32, @floatFromInt(b)) / 255.0,
            .a = @as(f32, @floatFromInt(a)) / 255.0,
        };
    }

    pub fn black() Color { return Color.rgb(0, 0, 0); }
    pub fn white() Color { return Color.rgb(255, 255, 255); }
    pub fn gray(v: u8) Color { return Color.rgb(v, v, v); }
};
