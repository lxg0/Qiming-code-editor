const std = @import("std");

pub const EditMode = enum {
    normal,
    insert,
    visual,
    visual_line,
    visual_block,
    command,
    search,
    replace,
};

pub const ModeManager = struct {
    current: EditMode,
    previous: EditMode,
    vim_mode: bool,

    pub fn init() ModeManager {
        return ModeManager{
            .current = .insert,
            .previous = .insert,
            .vim_mode = false,
        };
    }

    pub fn set(self: *ModeManager, mode: EditMode) void {
        self.previous = self.current;
        self.current = mode;
    }

    pub fn revert(self: *ModeManager) void {
        const temp = self.current;
        self.current = self.previous;
        self.previous = temp;
    }

    pub fn isNormal(self: *const ModeManager) bool {
        return self.current == .normal;
    }

    pub fn isInsert(self: *const ModeManager) bool {
        return self.current == .insert;
    }

    pub fn isVisual(self: *const ModeManager) bool {
        return self.current == .visual or self.current == .visual_line or self.current == .visual_block;
    }

    pub fn isCommand(self: *const ModeManager) bool {
        return self.current == .command or self.current == .search;
    }
};
