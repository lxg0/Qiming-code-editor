const std = @import("std");

pub const GestureKind = enum {
    click,
    double_click,
    triple_click,
    drag,
    swipe_left,
    swipe_right,
    swipe_up,
    swipe_down,
    pinch_in,
    pinch_out,
};

pub const GestureEvent = struct {
    kind: GestureKind,
    x: f32,
    y: f32,
    button: u8,
    delta_x: f32,
    delta_y: f32,
};

pub const GestureRecognizer = struct {
    click_timer: u64,
    last_click_x: f32,
    last_click_y: f32,
    click_count: u8,
    double_click_threshold_ms: u64 = 300,
    double_click_distance: f32 = 5,

    pub fn init() GestureRecognizer {
        return GestureRecognizer{
            .click_timer = 0,
            .last_click_x = 0,
            .last_click_y = 0,
            .click_count = 0,
        };
    }

    pub fn onMouseDown(self: *GestureRecognizer, x: f32, y: f32, timestamp: u64) GestureKind {
        const dt = timestamp - self.click_timer;
        const dx = x - self.last_click_x;
        const dy = y - self.last_click_y;
        const dist = @sqrt(dx * dx + dy * dy);

        if (dt < self.double_click_threshold_ms and dist < self.double_click_distance) {
            self.click_count = @min(self.click_count + 1, 3);
        } else {
            self.click_count = 1;
        }

        self.click_timer = timestamp;
        self.last_click_x = x;
        self.last_click_y = y;

        return switch (self.click_count) {
            1 => .click,
            2 => .double_click,
            3 => .triple_click,
            else => .click,
        };
    }
};
