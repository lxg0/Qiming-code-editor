const std = @import("std");
const Protocol = @import("Protocol.zig");

pub const DiagnosticSet = struct {
    allocator: std.mem.Allocator,
    diagnostics: std.array_list.Managed(Protocol.Diagnostic),

    pub fn init(allocator: std.mem.Allocator) DiagnosticSet {
        return DiagnosticSet{ .allocator = allocator, .diagnostics = std.array_list.Managed(Protocol.Diagnostic).init(allocator) };
    }

    pub fn deinit(self: *DiagnosticSet) void {
        self.diagnostics.deinit();
    }

    pub fn clear(self: *DiagnosticSet) void {
        self.diagnostics.clearRetainingCapacity();
    }

    pub fn add(self: *DiagnosticSet, diag: Protocol.Diagnostic) !void {
        try self.diagnostics.append(diag);
    }

    pub fn count(self: *const DiagnosticSet) usize {
        return self.diagnostics.items.len;
    }

    pub fn errorCount(self: *const DiagnosticSet) usize {
        var count: usize = 0;
        for (self.diagnostics.items) |d| {
            if (d.severity == .error) count += 1;
        }
        return count;
    }

    pub fn warningCount(self: *const DiagnosticSet) usize {
        var count: usize = 0;
        for (self.diagnostics.items) |d| {
            if (d.severity == .warning) count += 1;
        }
        return count;
    }

    pub fn getDiagnosticsAtLine(self: *const DiagnosticSet, line: usize) !std.array_list.Managed(Protocol.Diagnostic) {
        var result = std.array_list.Managed(Protocol.Diagnostic).init(self.allocator);
        for (self.diagnostics.items) |d| {
            if (d.range.start.line <= line and d.range.end.line >= line) {
                try result.append(d);
            }
        }
        return result;
    }
};
