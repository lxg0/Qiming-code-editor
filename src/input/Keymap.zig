const std = @import("std");
const Input = @import("Input.zig");
const Key = Input.Key;
const Modifiers = Input.Modifiers;

pub const Action = union(enum) {
    // Editing
    insert_newline,
    insert_tab,
    backspace,
    delete,
    undo,
    redo,
    cut,
    copy,
    paste,
    select_all,

    // Navigation
    cursor_left,
    cursor_right,
    cursor_up,
    cursor_down,
    cursor_word_left,
    cursor_word_right,
    cursor_line_start,
    cursor_line_end,
    cursor_file_start,
    cursor_file_end,
    page_up,
    page_down,

    // Selection
    select_left,
    select_right,
    select_up,
    select_down,
    select_word_left,
    select_word_right,
    select_line_start,
    select_line_end,
    select_all_occurrences,

    // Editing operations
    indent,
    unindent,
    toggle_comment,
    format_document,
    move_line_up,
    move_line_down,
    duplicate_line,

    // File operations
    save,
    save_as,
    open,
    close,
    quit,

    // Editor commands
    command_palette,
    toggle_sidebar,
    toggle_terminal,
    toggle_minimap,
    search,
    search_in_files,
    go_to_line,
    go_to_definition,
    go_to_symbol,

    // Layout
    increase_font_size,
    decrease_font_size,
    reset_font_size,
    toggle_fullscreen,
    zen_mode,

    // Multi-cursor
    add_cursor_up,
    add_cursor_down,
    add_cursor_at_click,
    remove_cursor,

    // AI
    ai_assist,
    ai_complete,
    ai_explain,
    ai_chat,

    // Mode
    enter_command_mode,
    enter_normal_mode,
    enter_insert_mode,
    enter_visual_mode,
};

pub const Binding = struct {
    key: Key,
    modifiers: Modifiers,
    action: Action,
};

pub const KeymapManager = struct {
    allocator: std.mem.Allocator,
    bindings: std.array_list.Managed(Binding),

    pub fn init(allocator: std.mem.Allocator) !KeymapManager {
        var km = KeymapManager{
            .allocator = allocator,
            .bindings = std.array_list.Managed(Binding).init(allocator),
        };
        try km.loadDefaults();
        return km;
    }

    pub fn deinit(self: *KeymapManager) void {
        self.bindings.deinit();
    }

    pub fn loadDefaults(self: *KeymapManager) !void {
        try self.bindings.appendSlice(&.{
            .{ .key = .enter, .modifiers = .none(), .action = .insert_newline },
            .{ .key = .tab, .modifiers = .none(), .action = .insert_tab },
            .{ .key = .backspace, .modifiers = .none(), .action = .backspace },
            .{ .key = .delete, .modifiers = .none(), .action = .delete },
            .{ .key = .arrow_left, .modifiers = .none(), .action = .cursor_left },
            .{ .key = .arrow_right, .modifiers = .none(), .action = .cursor_right },
            .{ .key = .arrow_up, .modifiers = .none(), .action = .cursor_up },
            .{ .key = .arrow_down, .modifiers = .none(), .action = .cursor_down },
            .{ .key = .home, .modifiers = .none(), .action = .cursor_line_start },
            .{ .key = .end, .modifiers = .none(), .action = .cursor_line_end },
            .{ .key = .page_up, .modifiers = .none(), .action = .page_up },
            .{ .key = .page_down, .modifiers = .none(), .action = .page_down },
        });
    }

    pub fn bind(self: *KeymapManager, key: Key, modifiers: Modifiers, action: Action) !void {
        try self.bindings.append(.{ .key = key, .modifiers = modifiers, .action = action });
    }

    pub fn lookup(self: *const KeymapManager, key: Key, modifiers: Modifiers) ?Action {
        for (self.bindings.items) |b| {
            if (matches(b, key, modifiers)) return b.action;
        }
        return null;
    }

    fn matches(binding: Binding, key: Key, modifiers: Modifiers) bool {
        if (!std.meta.eql(binding.key, key)) return false;
        return binding.modifiers.ctrl == modifiers.ctrl and
               binding.modifiers.alt == modifiers.alt and
               binding.modifiers.shift == modifiers.shift and
               binding.modifiers.meta == modifiers.meta;
    }
};
