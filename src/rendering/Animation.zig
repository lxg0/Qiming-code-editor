const std = @import("std");

pub const Easing = enum {
    linear,
    ease_in,
    ease_out,
    ease_in_out,
    bounce,
};

pub const Animation = struct {
    start_value: f32,
    end_value: f32,
    duration_ms: u64,
    elapsed_ms: u64,
    easing: Easing,
    playing: bool,

    pub fn init(start: f32, end: f32, duration_ms: u64) Animation {
        return Animation{
            .start_value = start,
            .end_value = end,
            .duration_ms = duration_ms,
            .elapsed_ms = 0,
            .easing = .ease_out,
            .playing = true,
        };
    }

    pub fn update(self: *Animation, dt_ms: u64) void {
        if (!self.playing) return;
        self.elapsed_ms = @min(self.elapsed_ms + dt_ms, self.duration_ms);
        if (self.elapsed_ms >= self.duration_ms) self.playing = false;
    }

    pub fn value(self: *const Animation) f32 {
        if (self.duration_ms == 0) return self.end_value;
        const t = @as(f32, @floatFromInt(self.elapsed_ms)) / @as(f32, @floatFromInt(self.duration_ms));
        const eased = applyEasing(t, self.easing);
        return self.start_value + (self.end_value - self.start_value) * eased;
    }

    pub fn isFinished(self: *const Animation) bool {
        return !self.playing;
    }

    fn applyEasing(t: f32, easing: Easing) f32 {
        return switch (easing) {
            .linear => t,
            .ease_in => t * t,
            .ease_out => 1 - (1 - t) * (1 - t),
            .ease_in_out => if (t < 0.5) 2 * t * t else 1 - @as(f32, @pow(2, -2 * t + 2)) * 0.5,
            .bounce => {
                const n1: f32 = 7.5625;
                const d1: f32 = 2.75;
                if (t < 1 / d1) return n1 * t * t;
                if (t < 2 / d1) return n1 * (t - 1.5 / d1) * (t - 1.5 / d1) + 0.75;
                if (t < 2.5 / d1) return n1 * (t - 2.25 / d1) * (t - 2.25 / d1) + 0.9375;
                return n1 * (t - 2.625 / d1) * (t - 2.625 / d1) + 0.984375;
            },
        };
    }
};
