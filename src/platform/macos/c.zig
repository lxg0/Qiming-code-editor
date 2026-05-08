//! macOS C FFI bindings
//! Wraps Objective-C runtime, AppKit, Metal, Foundation via @cImport

const std = @import("std");

pub const objc = @cImport({
    @cInclude("objc/runtime.h");
    @cInclude("objc/message.h");
});

pub const appkit = @cImport({
    @cInclude("AppKit/AppKit.h");
});

pub const metal = @cImport({
    @cInclude("Metal/Metal.h");
});

pub const foundation = @cImport({
    @cInclude("Foundation/Foundation.h");
});

// Convenience: send an objc message with no args
pub fn msgSend(obj: anytype, selector: objc.SEL) callconv(.C) void {
    _ = obj;
    _ = selector;
}

// Send objc message with one arg
pub fn msgSend1(obj: anytype, selector: objc.SEL, arg: anytype) callconv(.C) void {
    _ = obj;
    _ = selector;
    _ = arg;
}

// Helper types
pub const id = ?*anyopaque;
pub const SEL = objc.SEL;

// Alloc and init patterns
pub fn alloc(class: id) id {
    return objc.objc_msgSend(class, objc.sel_registerName("alloc"));
}

pub fn init(obj: id) id {
    return objc.objc_msgSend(obj, objc.sel_registerName("init"));
}

pub fn retain(obj: id) void {
    _ = objc.objc_msgSend(obj, objc.sel_registerName("retain"));
}

pub fn release(obj: id) void {
    _ = objc.objc_msgSend(obj, objc.sel_registerName("release"));
}

/// Get the Objective-C class by name (as a C string)
pub fn getClass(name: [*:0]const u8) id {
    return objc.objc_getClass(name);
}

/// Register a selector by name
pub fn sel(name: [*:0]const u8) SEL {
    return objc.sel_registerName(name);
}

/// Cast void pointer to ObjC object type
pub fn asObject(ptr: *anyopaque) id {
    return @ptrCast(ptr);
}
