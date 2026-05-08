const std = @import("std");
const Buffer = @import("../buffer/Buffer.zig").Buffer;
const SelectionSet = @import("../buffer/Selection.zig").SelectionSet;
const UndoManager = @import("../buffer/Undo.zig").UndoManager;
const EditBatch = @import("../buffer/Edit.zig").EditBatch;

pub const Document = struct {
    allocator: std.mem.Allocator,
    buffer: Buffer,
    selections: SelectionSet,
    undo_manager: UndoManager,
    file_path: ?[]u8,
    language: []const u8,
    encoding: Buffer.Encoding,
    line_ending: Buffer.LineEnding,
    is_dirty: bool,
    id: u64,

    pub fn create(allocator: std.mem.Allocator, initial_text: []const u8) !*Document {
        const doc = try allocator.create(Document);
        errdefer allocator.destroy(doc);
        doc.* = try init(allocator, initial_text);
        return doc;
    }

    pub fn init(allocator: std.mem.Allocator, initial_text: []const u8) !Document {
        return Document{
            .allocator = allocator,
            .buffer = try Buffer.init(allocator, initial_text),
            .selections = SelectionSet.init(allocator),
            .undo_manager = UndoManager.init(allocator, 1000),
            .file_path = null,
            .language = "text",
            .encoding = .utf8,
            .line_ending = .lf,
            .is_dirty = false,
            .id = @intCast(@import("../util/Async.zig").timestampMs()),
        };
    }

    pub fn deinit(self: *Document) void {
        self.buffer.deinit();
        self.selections.deinit();
        self.undo_manager.deinit();
        if (self.file_path) |p| self.allocator.free(p);
    }

    pub fn destroy(self: *Document) void {
        self.deinit();
        self.allocator.destroy(self);
    }

    pub fn insert(self: *Document, position: usize, text: []const u8) !void {
        try self.buffer.insert(position, text);
        self.is_dirty = true;
    }

    pub fn delete(self: *Document, position: usize, length: usize) !void {
        try self.buffer.delete(position, length);
        self.is_dirty = true;
    }

    pub fn editBatch(self: *Document, label: []const u8) !EditBatch {
        return EditBatch.init(self.allocator, label);
    }

    pub fn recordEdit(self: *Document, batch: EditBatch) !void {
        try self.undo_manager.record(batch);
    }

    pub fn undo(self: *Document) !void {
        try self.undo_manager.undo(&self.buffer);
        self.is_dirty = !self.undo_manager.isSavePoint();
    }

    pub fn redo(self: *Document) !void {
        try self.undo_manager.redo(&self.buffer);
        self.is_dirty = !self.undo_manager.isSavePoint();
    }

    pub fn setFilePath(self: *Document, path: []const u8) !void {
        if (self.file_path) |p| self.allocator.free(p);
        self.file_path = try self.allocator.dupe(u8, path);
        self.is_dirty = false;
        self.undo_manager.markSavePoint();
        // Detect language from extension
        self.language = detectLanguage(path);
    }

    pub fn fileName(self: *const Document) []const u8 {
        const path = self.file_path orelse return "未命名";
        if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| return path[i + 1..];
        if (std.mem.lastIndexOfScalar(u8, path, '\\')) |i| return path[i + 1..];
        return path;
    }

    pub fn lineCount(self: *const Document) usize {
        return self.buffer.lineCount();
    }

    pub fn totalChars(self: *const Document) usize {
        return self.buffer.len();
    }
};

fn detectLanguage(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    const map = std.static_string_map.StaticStringMap([]const u8).initComptime(.{
        .{ ".zig", "zig" },
        .{ ".rs", "rust" },
        .{ ".go", "go" },
        .{ ".py", "python" },
        .{ ".js", "javascript" },
        .{ ".ts", "typescript" },
        .{ ".tsx", "typescriptreact" },
        .{ ".jsx", "javascriptreact" },
        .{ ".html", "html" },
        .{ ".css", "css" },
        .{ ".scss", "scss" },
        .{ ".json", "json" },
        .{ ".yaml", "yaml" },
        .{ ".yml", "yaml" },
        .{ ".toml", "toml" },
        .{ ".md", "markdown" },
        .{ ".c", "c" },
        .{ ".h", "c" },
        .{ ".cpp", "cpp" },
        .{ ".hpp", "cpp" },
        .{ ".cc", "cpp" },
        .{ ".java", "java" },
        .{ ".rb", "ruby" },
        .{ ".php", "php" },
        .{ ".swift", "swift" },
        .{ ".kt", "kotlin" },
        .{ ".dart", "dart" },
        .{ ".lua", "lua" },
        .{ ".sh", "shellscript" },
        .{ ".bash", "shellscript" },
        .{ ".zsh", "shellscript" },
        .{ ".sql", "sql" },
        .{ ".r", "r" },
        .{ ".tex", "latex" },
        .{ ".xml", "xml" },
        .{ ".vue", "vue" },
        .{ ".svelte", "svelte" },
    });
    return map.get(ext) orelse "text";
}
