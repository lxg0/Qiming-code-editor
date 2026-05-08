pub const Buffer = @import("Buffer.zig").Buffer;
pub const PieceTable = @import("PieceTable.zig").PieceTable;
pub const GapBuffer = @import("Buffer.zig").GapBuffer;
pub const Cursor = @import("Cursor.zig").Cursor;
pub const Selection = @import("Selection.zig").Selection;
pub const SelectionSet = @import("Selection.zig").SelectionSet;
pub const Undo = @import("Undo.zig").Undo;
pub const Edit = @import("Edit.zig").Edit;
pub const simd = @import("simd.zig");

test "buffer module" {
    _ = @import("PieceTable.zig");
    _ = @import("Buffer.zig");
}
