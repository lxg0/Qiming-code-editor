pub const Editor = @import("Editor.zig").Editor;
pub const Document = @import("Document.zig").Document;
pub const View = @import("View.zig").View;
pub const Mode = @import("Mode.zig").ModeManager;
pub const MultiCursor = @import("MultiCursor.zig").MultiCursor;
pub const Snippet = @import("Snippet.zig").Snippet;
pub const SnippetManager = @import("Snippet.zig").SnippetManager;

test "editor module" {
    _ = @import("Editor.zig");
    _ = @import("Document.zig");
}
