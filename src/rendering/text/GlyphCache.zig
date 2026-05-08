const std = @import("std");

pub const CachedGlyph = struct {
    codepoint: u21,
    size: f32,
    bitmap: []u8,
    width: u32,
    height: u32,
    bearing_x: i32,
    bearing_y: i32,
    advance: f32,
};

pub const GlyphCache = struct {
    allocator: std.mem.Allocator,
    entries: std.AutoHashMap(u64, CachedGlyph),
    max_size: usize,

    pub fn init(allocator: std.mem.Allocator) GlyphCache {
        return GlyphCache{
            .allocator = allocator,
            .entries = std.AutoHashMap(u64, CachedGlyph).init(allocator),
            .max_size = 4096,
        };
    }

    pub fn deinit(self: *GlyphCache) void {
        var it = self.entries.valueIterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.bitmap);
        }
        self.entries.deinit();
    }

    pub fn key(codepoint: u21, size: f32) u64 {
        return (@as(u64, codepoint) << 32) | @as(u64, @bitCast(size));
    }

    pub fn get(self: *GlyphCache, codepoint: u21, size: f32) ?CachedGlyph {
        return self.entries.get(key(codepoint, size));
    }

    pub fn insert(self: *GlyphCache, glyph: CachedGlyph) !void {
        if (self.entries.count() >= self.max_size) {
            self.evict();
        }
        try self.entries.put(key(glyph.codepoint, glyph.size), glyph);
    }

    pub fn clear(self: *GlyphCache) void {
        var it = self.entries.valueIterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.bitmap);
        }
        self.entries.clearRetainingCapacity();
    }

    fn evict(self: *GlyphCache) void {
        var it = self.entries.iterator();
        if (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.bitmap);
            _ = self.entries.remove(entry.key_ptr.*);
        }
    }
};
