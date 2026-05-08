const std = @import("std");

/// SIMD-accelerated byte search with full UTF-8 awareness
pub fn findByte(slice: []const u8, byte: u8) ?usize {
    if (slice.len == 0) return null;
    const ptr = slice.ptr;
    const len = slice.len;
    var i: usize = 0;
    if (len >= 32) {
        while (i + 32 <= len) : (i += 32) {
            const v: @Vector(32, u8) = ptr[i..][0..32].*;
            const cmp = v == @as(@Vector(32, u8), @splat(byte));
            const mask: u32 = @bitCast(cmp);
            if (mask != 0) return i + @ctz(mask);
        }
    }
    if (len - i >= 16) {
        const v: @Vector(16, u8) = ptr[i..][0..16].*;
        const cmp = v == @as(@Vector(16, u8), @splat(byte));
        const mask: u16 = @bitCast(cmp);
        if (mask != 0) return i + @ctz(mask);
        i += 16;
    }
    while (i < len) : (i += 1) {
        if (ptr[i] == byte) return i;
    }
    return null;
}

pub fn rfindByte(slice: []const u8, byte: u8) ?usize {
    if (slice.len == 0) return null;
    const ptr = slice.ptr;
    var i = slice.len;
    if (i >= 32) {
        while (i >= 32) : (i -= 32) {
            const v: @Vector(32, u8) = ptr[i - 32 ..][0..32].*;
            const cmp = v == @as(@Vector(32, u8), @splat(byte));
            const mask: u32 = @bitCast(cmp);
            if (mask != 0) return i - 32 + 31 - @clz(mask);
        }
    }
    if (i >= 16) {
        const v: @Vector(16, u8) = ptr[i - 16 ..][0..16].*;
        const cmp = v == @as(@Vector(16, u8), @splat(byte));
        const mask: u16 = @bitCast(cmp);
        if (mask != 0) return i - 16 + 15 - @clz(mask);
        i -= 16;
    }
    while (i > 0) : (i -= 1) {
        if (ptr[i - 1] == byte) return i - 1;
    }
    return null;
}

pub fn countBytes(slice: []const u8, byte: u8) usize {
    if (slice.len == 0) return 0;
    const ptr = slice.ptr;
    const len = slice.len;
    var i: usize = 0;
    var count: usize = 0;
    if (len >= 32) {
        while (i + 32 <= len) : (i += 32) {
            const v: @Vector(32, u8) = ptr[i..][0..32].*;
            const cmp = v == @as(@Vector(32, u8), @splat(byte));
            const mask: u32 = @bitCast(cmp);
            count += @popCount(mask);
        }
    }
    if (len - i >= 16) {
        const v: @Vector(16, u8) = ptr[i..][0..16].*;
        const cmp = v == @as(@Vector(16, u8), @splat(byte));
        const mask: u16 = @bitCast(cmp);
        count += @popCount(mask);
        i += 16;
    }
    while (i < len) : (i += 1) {
        if (ptr[i] == byte) count += 1;
    }
    return count;
}

pub fn findUtf8Char(slice: []const u8, codepoint: u21) ?usize {
    var i: usize = 0;
    while (i < slice.len) {
        const cp = std.unicode.utf8Decode(slice[i..]) catch {
            i += 1;
            continue;
        };
        if (cp == codepoint) return i;
        i += std.unicode.utf8CodepointSequenceLength(cp) catch 1;
    }
    return null;
}

pub fn countUtf8Chars(slice: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < slice.len) {
        const cp = std.unicode.utf8Decode(slice[i..]) catch {
            i += 1;
            continue;
        };
        count += 1;
        i += std.unicode.utf8CodepointSequenceLength(cp) catch 1;
    }
    return count;
}

pub fn isCjkChar(cp: u21) bool {
    return (cp >= 0x4E00 and cp <= 0x9FFF) or // CJK Unified Ideographs
           (cp >= 0x3400 and cp <= 0x4DBF) or // CJK Extension A
           (cp >= 0x2E80 and cp <= 0x2EFF) or // CJK Radicals
           (cp >= 0x3000 and cp <= 0x303F) or // CJK Symbols
           (cp >= 0xFF00 and cp <= 0xFFEF) or // Fullwidth Forms
           (cp >= 0x20000 and cp <= 0x2A6DF) or // CJK Extension B
           (cp >= 0xF900 and cp <= 0xFAFF) or // CJK Compatibility
           (cp >= 0xFE30 and cp <= 0xFE4F); // CJK Compatibility Forms
}

pub fn cjkCharWidth(cp: u21) u8 {
    return if (isCjkChar(cp)) 2 else 1;
}

pub fn stringDisplayWidth(text: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;
    while (i < text.len) {
        const cp = std.unicode.utf8Decode(text[i..]) catch {
            i += 1;
            width += 1;
            continue;
        };
        width += cjkCharWidth(cp);
        i += std.unicode.utf8CodepointSequenceLength(cp) catch 1;
    }
    return width;
}

test "findByte" {
    try std.testing.expectEqual(@as(?usize, 3), findByte("hello", 'l'));
    try std.testing.expectEqual(@as(?usize, null), findByte("hi", 'x'));
}

test "countBytes" {
    try std.testing.expectEqual(@as(usize, 3), countBytes("hello world", 'o'));
}

test "stringDisplayWidth CJK" {
    try std.testing.expectEqual(@as(usize, 4), stringDisplayWidth("中文"));
    try std.testing.expectEqual(@as(usize, 5), stringDisplayWidth("hello"));
}
