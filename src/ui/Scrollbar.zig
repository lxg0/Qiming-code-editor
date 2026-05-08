const std = @import("std");

pub const Scrollbar = struct {
    content_size: f32,
    viewport_size: f32,
    scroll_offset: f32,
    width: f32,
    visible: bool,
    dragging: bool,

    pub fn init() Scrollbar {
        return Scrollbar{
            .content_size = 0,
            .viewport_size = 0,
            .scroll_offset = 0,
            .width = 14,
            .visible = true,
            .dragging = false,
        };
    }

    pub fn thumbSize(self: *const Scrollbar) f32 {
        if (self.content_size <= 0) return self.viewport_size;
        const ratio = self.viewport_size / self.content_size;
        return @max(self.viewport_size * ratio, 20);
    }

    pub fn thumbPosition(self: *const Scrollbar) f32 {
        if (self.content_size <= self.viewport_size) return 0;
        const max_scroll = self.content_size - self.viewport_size;
        const ratio = self.scroll_offset / max_scroll;
        return (self.viewport_size - self.thumbSize()) * ratio;
    }

    pub fn isScrollNeeded(self: *const Scrollbar) bool {
        return self.content_size > self.viewport_size;
    }

    pub fn setContent(self: *Scrollbar, content: f32, viewport: f32, offset: f32) void {
        self.content_size = content;
        self.viewport_size = viewport;
        self.scroll_offset = offset;
        self.visible = self.isScrollNeeded();
    }
};
