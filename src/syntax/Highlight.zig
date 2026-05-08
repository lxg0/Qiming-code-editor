const std = @import("std");
const Syntax = @import("Syntax.zig");
const Token = Syntax.Token;
const TokenType = Syntax.TokenType;

pub const HighlightResult = struct {
    line: usize,
    tokens: []Token,
};

pub const Highlighter = struct {
    allocator: std.mem.Allocator,
    engine: Syntax.SyntaxEngine,

    pub fn init(allocator: std.mem.Allocator) Highlighter {
        return Highlighter{ .allocator = allocator, .engine = Syntax.SyntaxEngine.init(allocator) };
    }

    pub fn deinit(self: *Highlighter) void {
        self.engine.deinit();
    }

    pub fn highlightLine(self: *Highlighter, line: []const u8, line_num: usize) !Syntax.HighlightLine {
        return self.engine.highlightLine(line, line_num);
    }

    pub fn tokenTypeToColor(ttype: TokenType) []const u8 {
        return switch (ttype) {
            .keyword => "keyword",
            .string => "string",
            .number => "number",
            .comment => "comment",
            .function => "function",
            .type => "type",
            .variable => "variable",
            .constant => "constant",
            .operator => "operator",
            .punctuation => "punctuation",
            .parameter => "parameter",
            .property => "property",
            .tag => "tag",
            .attribute => "attribute",
            .regex => "regex",
            .markup_bold => "markup_bold",
            .markup_italic => "markup_italic",
            .markup_heading => "markup_heading",
            .markup_link => "markup_link",
            .markup_list => "markup_list",
            .markup_quote => "markup_quote",
            .markup_inline_code => "markup_inline_code",
            .markup_code_block => "markup_code_block",
            else => "unknown",
        };
    }
};
