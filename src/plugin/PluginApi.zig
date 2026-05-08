const std = @import("std");
const Editor = @import("../editor/Editor.zig").Editor;

/// VS Code Extension API surface implemented in Zig.
/// Extensions compiled to WASM call these via import thunks.
pub const PluginApi = struct {
    editor: *Editor,
    allocator: std.mem.Allocator,
    version: []const u8,

    pub fn init(editor: *Editor, allocator: std.mem.Allocator) PluginApi {
        return .{ .editor = editor, .allocator = allocator, .version = "1.97.0" };
    }

    // ── VS Code `vscode.workspace` ───────────────────────────────────────────

    pub fn getWorkspaceFolders(self: *const PluginApi) [][]const u8 {
        _ = self;
        return &.{};
    }

    pub fn openTextDocument(self: *const PluginApi, path: []const u8) !void {
        try self.editor.openFile(path);
    }

    // ── VS Code `vscode.window` ──────────────────────────────────────────────

    pub fn showInformationMessage(self: *const PluginApi, msg: []const u8) void {
        _ = self;
        std.debug.print("[Plugin] Info: {s}\n", .{msg});
    }

    pub fn showErrorMessage(self: *const PluginApi, msg: []const u8) void {
        _ = self;
        std.debug.print("[Plugin] Error: {s}\n", .{msg});
    }

    pub fn setStatusBarMessage(self: *const PluginApi, msg: []const u8) void {
        _ = self;
        std.debug.print("[Plugin] Status: {s}\n", .{msg});
    }

    // ── VS Code `vscode.languages` ──────────────────────────────────────────

    pub fn registerCompletionProvider(self: *const PluginApi, language: []const u8, provider: anytype) void {
        _ = self; _ = language; _ = provider;
    }

    pub fn registerHoverProvider(self: *const PluginApi, language: []const u8, provider: anytype) void {
        _ = self; _ = language; _ = provider;
    }

    pub fn registerDefinitionProvider(self: *const PluginApi, language: []const u8, provider: anytype) void {
        _ = self; _ = language; _ = provider;
    }

    // ── VS Code `vscode.commands` ───────────────────────────────────────────

    pub fn registerCommand(self: *const PluginApi, name: []const u8, handler: *const fn () void) void {
        _ = self;
        std.debug.print("[Plugin] 注册命令: {s}\n", .{name});
        _ = handler;
    }

    pub fn executeCommand(self: *const PluginApi, name: []const u8) void {
        _ = self;
        std.debug.print("[Plugin] 执行命令: {s}\n", .{name});
    }
};
