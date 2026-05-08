const std = @import("std");
const Arena = @import("Arena.zig").ArenaAllocator;

pub const Allocator = struct {
    // Global page allocator for large buffers
    pub fn pageAllocator() std.mem.Allocator {
        return std.heap.page_allocator;
    }

    // Arena allocator for scratch allocations
    pub fn arenaAllocator(backing: std.mem.Allocator, block_size: usize) ArenaAllocator {
        return ArenaAllocator.init(backing, block_size);
    }

    // Bump allocator for single-frame allocations
    pub const BumpAllocator = struct {
        buffer: []u8,
        offset: usize,

        pub fn init(buffer: []u8) BumpAllocator {
            return BumpAllocator{ .buffer = buffer, .offset = 0 };
        }

        pub fn allocator(self: *BumpAllocator) std.mem.Allocator {
            return .{
                .ptr = self,
                .vtable = &.{
                    .alloc = bumpAlloc,
                    .resize = bumpResize,
                    .free = bumpFree,
                },
            };
        }

        fn bumpAlloc(ctx: *anyopaque, len: usize, ptr_align: u8, ra: usize) ?[*]u8 {
            _ = ptr_align;
            _ = ra;
            const self: *BumpAllocator = @ptrCast(@alignCast(ctx));
            if (self.offset + len > self.buffer.len) return null;
            const result = self.buffer[self.offset..][0..len];
            self.offset += len;
            return result.ptr;
        }

        fn bumpResize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ra: usize) bool {
            _ = ctx;
            _ = buf;
            _ = buf_align;
            _ = new_len;
            _ = ra;
            return false;
        }

        fn bumpFree(ctx: *anyopaque, buf: []u8, buf_align: u8, ra: usize) void {
            _ = ctx;
            _ = buf;
            _ = buf_align;
            _ = ra;
        }

        pub fn reset(self: *BumpAllocator) void {
            self.offset = 0;
        }
    };
};
