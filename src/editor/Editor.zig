const std = @import("std");
const Document = @import("Document.zig").Document;
const View = @import("View.zig").View;
const ModeManager = @import("Mode.zig").ModeManager;
const MultiCursor = @import("MultiCursor.zig").MultiCursor;
const EditBatch = @import("../buffer/Edit.zig").EditBatch;
const UndoManager = @import("../buffer/Undo.zig").UndoManager;

pub const Editor = struct {
    allocator: std.mem.Allocator,
    documents: std.array_list.Managed(*Document),
    views: std.array_list.Managed(*View),
    active_document_index: usize,
    active_view_index: usize,
    mode: ModeManager,
    multi_cursor: MultiCursor,
    clipboards: std.array_list.Managed([]u8),

    pub fn init(allocator: std.mem.Allocator) !Editor {
        var editor = Editor{
            .allocator = allocator,
            .documents = std.array_list.Managed(*Document).init(allocator),
            .views = std.array_list.Managed(*View).init(allocator),
            .active_document_index = 0,
            .active_view_index = 0,
            .mode = ModeManager.init(),
            .multi_cursor = MultiCursor.init(allocator),
            .clipboards = std.array_list.Managed([]u8).init(allocator),
        };
        // Create default document
        const doc = try Document.create(allocator, "");
        try editor.documents.append(doc);
        const view = try allocator.create(View);
        view.* = try View.init(allocator, doc);
        try editor.views.append(view);
        return editor;
    }

    pub fn deinit(self: *Editor) void {
        for (self.documents.items) |doc| doc.destroy();
        self.documents.deinit();
        for (self.views.items) |view| {
            view.deinit();
            self.allocator.destroy(view);
        }
        self.views.deinit();
        self.multi_cursor.deinit();
        for (self.clipboards.items) |c| self.allocator.free(c);
        self.clipboards.deinit();
    }

    pub fn activeDocument(self: *const Editor) *Document {
        return self.documents.items[self.active_document_index];
    }

    pub fn activeView(self: *const Editor) *View {
        return self.views.items[self.active_view_index];
    }

    pub fn activeDocumentMut(self: *Editor) *Document {
        return self.documents.items[self.active_document_index];
    }

    pub fn openFile(self: *Editor, path: []const u8) !void {
        // Check if already open
        for (self.documents.items) |doc| {
            if (doc.file_path) |fp| {
                if (std.mem.eql(u8, fp, path)) return;
            }
        }
        // Read file
        var threaded_io = std.Io.Threaded.init(self.allocator, .{});
        defer threaded_io.deinit();
        const io: std.Io = threaded_io.io();
        const content = try std.Io.Dir.readFileAlloc(.cwd(), io, path, self.allocator, std.Io.Limit.limited(10 * 1024 * 1024));
        defer self.allocator.free(content);
        const doc = try Document.create(self.allocator, content);
        try doc.setFilePath(path);
        try self.documents.append(doc);
        const view = try self.allocator.create(View);
        view.* = try View.init(self.allocator, doc);
        try self.views.append(view);
        self.active_document_index = self.documents.items.len - 1;
        self.active_view_index = self.views.items.len - 1;
    }

    pub fn saveFile(self: *Editor, path: ?[]const u8) !void {
        const doc = self.activeDocument();
        const save_path = path orelse doc.file_path orelse return error.NoPath;
        const text = try doc.buffer.getText();
        defer self.allocator.free(text);
        var threaded_io = std.Io.Threaded.init(self.allocator, .{});
        defer threaded_io.deinit();
        const io: std.Io = threaded_io.io();
        std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = save_path, .data = text }) catch {};
        try doc.setFilePath(save_path);
    }

    pub fn closeDocument(self: *Editor, index: usize) void {
        if (index >= self.documents.items.len) return;
        var doc = self.documents.orderedRemove(index);
        var view = self.views.orderedRemove(index);
        view.deinit();
        self.allocator.destroy(view);
        doc.destroy();
        if (self.active_document_index >= self.documents.items.len) {
            self.active_document_index = if (self.documents.items.len > 0) self.documents.items.len - 1 else 0;
        }
        if (self.active_view_index >= self.views.items.len) {
            self.active_view_index = if (self.views.items.len > 0) self.views.items.len - 1 else 0;
        }
    }

    pub fn switchToDocument(self: *Editor, index: usize) void {
        if (index < self.documents.items.len) {
            self.active_document_index = index;
            self.active_view_index = index;
        }
    }

    pub fn insertAtCursor(self: *Editor, text: []const u8) !void {
        const doc = self.activeDocument();
        const view = self.activeView();
        const pos = view.primaryCursor().position;
        try doc.insert(pos, text);
        view.primaryCursorMut().setPosition(pos + text.len);
    }

    pub fn deleteAtCursor(self: *Editor, direction: enum { left, right }) !void {
        const doc = self.activeDocument();
        const view = self.activeView();
        const cursor = view.primaryCursor();
        const pos = cursor.position;
        if (direction == .left and pos > 0) {
            try doc.delete(pos - 1, 1);
            view.primaryCursorMut().setPosition(pos - 1);
        } else if (direction == .right and pos < doc.buffer.len()) {
            try doc.delete(pos, 1);
        }
    }

    pub fn cut(self: *Editor) !void {
        const doc = self.activeDocument();
        const text = try doc.buffer.getText();
        defer self.allocator.free(text);
        try self.clipboards.append(try self.allocator.dupe(u8, text));
        try doc.delete(0, doc.buffer.len());
    }

    pub fn copy(self: *Editor) !void {
        const doc = self.activeDocument();
        const text = try doc.buffer.getText();
        try self.clipboards.append(text);
    }

    pub fn paste(self: *Editor) !void {
        if (self.clipboards.items.len == 0) return;
        const text = self.clipboards.items[self.clipboards.items.len - 1];
        try self.insertAtCursor(text);
    }

    pub fn undo(self: *Editor) !void {
        const doc = self.activeDocument();
        try doc.undo();
    }

    pub fn redo(self: *Editor) !void {
        const doc = self.activeDocument();
        try doc.redo();
    }
};
