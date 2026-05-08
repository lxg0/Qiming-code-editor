const std = @import("std");

pub const ArenaAllocator = struct {
    const Block = struct {
        data: []u8,
        offset: usize,
        next: ?*Block,
    };

    allocator: std.mem.Allocator,
    current: ?*Block,
    total_allocated: usize,
    block_size: usize,

    pub fn init(allocator: std.mem.Allocator, block_size: usize) ArenaAllocator {
        return ArenaAllocator{
            .allocator = allocator,
            .current = null,
            .total_allocated = 0,
            .block_size = block_size,
        };
    }

    pub fn deinit(self: *ArenaAllocator) void {
        var block = self.current;
        while (block) |b| {
            const next = b.next;
            self.allocator.free(b.data);
            self.allocator.destroy(b);
            block = next;
        }
        self.current = null;
        self.total_allocated = 0;
    }

    pub fn allocator(self: *ArenaAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = allocFn,
                .resize = resizeFn,
                .free = freeFn,
            },
        };
    }

    fn allocFn(ctx: *anyopaque, len: usize, ptr_align: u8, ra: usize) ?[*]u8 {
        _ = ptr_align;
        _ = ra;
        const self: *ArenaAllocator = @ptrCast(@alignCast(ctx));
        const block = self.current orelse {
            const size = @max(self.block_size, len);
            return self.allocNewBlock(size, len);
        };
        const available = block.data.len - block.offset;
        if (available >= len) {
            const result = block.data[block.offset..][0..len];
            block.offset += len;
            return result.ptr;
        }
        const size = @max(self.block_size, len);
        return self.allocNewBlock(size, len);
    }

    fn allocNewBlock(self: *ArenaAllocator, size: usize, min_len: usize) ?[*]u8 {
        const alloc_size = if (size < min_len) min_len else size;
        const data = self.allocator.alloc(u8, alloc_size) catch return null;
        const block = self.allocator.create(Block) catch {
            self.allocator.free(data);
            return null;
        };
        block.* = .{
            .data = data,
            .offset = min_len,
            .next = self.current,
        };
        self.current = block;
        self.total_allocated += alloc_size;
        return data[0..min_len].ptr;
    }

    fn resizeFn(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ra: usize) bool {
        _ = ctx;
        _ = buf;
        _ = buf_align;
        _ = new_len;
        _ = ra;
        return false;
    }

    fn freeFn(ctx: *anyopaque, buf: []u8, buf_align: u8, ra: usize) void {
        _ = ctx;
        _ = buf;
        _ = buf_align;
        _ = ra;
    }

    pub fn reset(self: *ArenaAllocator) void {
        var block = self.current;
        while (block) |b| {
            b.offset = 0;
            block = b.next;
        }
    }

    pub fn dupe(self: *ArenaAllocator, comptime T: type, items: []const T) ![]T {
        const result = try self.allocator().alloc(T, items.len);
        @memcpy(result, items);
        return result;
    }
};
