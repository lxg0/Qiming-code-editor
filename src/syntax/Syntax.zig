const std = @import("std");

pub const TokenType = enum {
    keyword,
    string,
    number,
    comment,
    function,
    type,
    variable,
    constant,
    operator,
    punctuation,
    parameter,
    property,
    tag,
    attribute,
    regex,
    markup_bold,
    markup_italic,
    markup_heading,
    markup_link,
    markup_list,
    markup_quote,
    markup_inline_code,
    markup_code_block,
    whitespace,
    unknown,
};

pub const Token = struct {
    start: usize,
    end: usize,
    type: TokenType,
};

pub const HighlightLine = struct {
    tokens: std.array_list.Managed(Token),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HighlightLine {
        return HighlightLine{ .tokens = std.array_list.Managed(Token).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *HighlightLine) void {
        self.tokens.deinit();
    }

    pub fn addToken(self: *HighlightLine, start: usize, end: usize, token_type: TokenType) !void {
        try self.tokens.append(.{ .start = start, .end = end, .type = token_type });
    }
};

pub const SyntaxKind = enum {
    zig,
    rust,
    python,
    javascript,
    typescript,
    html,
    css,
    json,
    markdown,
    yaml,
    toml,
    c,
    cpp,
    java,
    go,
    ruby,
    php,
    swift,
    kotlin,
    dart,
    lua,
    shell,
    sql,
    text,
};

pub const SyntaxEngine = struct {
    allocator: std.mem.Allocator,
    kind: SyntaxKind,

    pub fn init(allocator: std.mem.Allocator) SyntaxEngine {
        return SyntaxEngine{ .allocator = allocator, .kind = .text };
    }

    pub fn deinit(self: *SyntaxEngine) void {
        _ = self;
    }

    pub fn setLanguage(self: *SyntaxEngine, kind: SyntaxKind) void {
        self.kind = kind;
    }

    pub fn setLanguageFromExt(self: *SyntaxEngine, ext: []const u8) void {
        self.kind = detectLanguage(ext);
    }

    pub fn highlightLine(self: *SyntaxEngine, line: []const u8, line_num: usize) !HighlightLine {
        _ = line_num;
        var hl = HighlightLine.init(self.allocator);
        errdefer hl.deinit();
        if (line.len == 0) {
            try hl.addToken(0, 0, .whitespace);
            return hl;
        }
        switch (self.kind) {
            .zig => return self.highlightZig(line),
            .python => return self.highlightPython(line),
            .javascript, .typescript => return self.highlightJsTs(line),
            .rust => return self.highlightRust(line),
            .html => return self.highlightHtml(line),
            .css => return self.highlightCss(line),
            .json => return self.highlightJson(line),
            .markdown => return self.highlightMarkdown(line),
            .c, .cpp => return self.highlightC(line),
            else => {
                try hl.addToken(0, line.len, .unknown);
                return hl;
            },
        }
    }

    fn highlightZig(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        var hl = HighlightLine.init(self.allocator);
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "const", .keyword }, .{ "var", .keyword }, .{ "fn", .keyword },
            .{ "pub", .keyword }, .{ "return", .keyword }, .{ "if", .keyword },
            .{ "else", .keyword }, .{ "for", .keyword }, .{ "while", .keyword },
            .{ "switch", .keyword }, .{ "break", .keyword }, .{ "continue", .keyword },
            .{ "defer", .keyword }, .{ "errdefer", .keyword }, .{ "try", .keyword },
            .{ "catch", .keyword }, .{ "null", .constant }, .{ "true", .constant },
            .{ "false", .constant }, .{ "struct", .type }, .{ "enum", .type },
            .{ "union", .type }, .{ "error", .type }, .{ "usingnamespace", .keyword },
            .{ "test", .keyword }, .{ "comptime", .keyword }, .{ "export", .keyword },
            .{ "extern", .keyword }, .{ "inline", .keyword }, .{ "noalias", .keyword },
            .{ "volatile", .keyword }, .{ "allowzero", .keyword }, .{ "anyopaque", .type },
            .{ "anytype", .type }, .{ "type", .type }, .{ "void", .type },
            .{ "bool", .type }, .{ "u8", .type }, .{ "u16", .type },
            .{ "u32", .type }, .{ "u64", .type }, .{ "i8", .type },
            .{ "i16", .type }, .{ "i32", .type }, .{ "i64", .type },
            .{ "f32", .type }, .{ "f64", .type }, .{ "usize", .type },
            .{ "isize", .type }, .{ "comptime_int", .type }, .{ "comptime_float", .type },
            .{ "anyerror", .type }, .{ "noreturn", .type },
        });
        return tokenizeLine(line, keywords);
    }

    fn highlightPython(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "def", .keyword }, .{ "class", .keyword }, .{ "return", .keyword },
            .{ "if", .keyword }, .{ "elif", .keyword }, .{ "else", .keyword },
            .{ "for", .keyword }, .{ "while", .keyword }, .{ "import", .keyword },
            .{ "from", .keyword }, .{ "as", .keyword }, .{ "with", .keyword },
            .{ "try", .keyword }, .{ "except", .keyword }, .{ "finally", .keyword },
            .{ "raise", .keyword }, .{ "pass", .keyword }, .{ "break", .keyword },
            .{ "continue", .keyword }, .{ "lambda", .keyword }, .{ "yield", .keyword },
            .{ "None", .constant }, .{ "True", .constant }, .{ "False", .constant },
            .{ "and", .operator }, .{ "or", .operator }, .{ "not", .operator },
            .{ "in", .operator }, .{ "is", .operator }, .{ "print", .function },
            .{ "len", .function }, .{ "range", .function }, .{ "int", .type },
            .{ "float", .type }, .{ "str", .type }, .{ "list", .type },
            .{ "dict", .type }, .{ "set", .type }, .{ "tuple", .type },
            .{ "self", .variable }, .{ "async", .keyword }, .{ "await", .keyword },
        });
        return tokenizeLine(line, keywords);
    }

    fn highlightJsTs(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "function", .keyword }, .{ "const", .keyword }, .{ "let", .keyword },
            .{ "var", .keyword }, .{ "return", .keyword }, .{ "if", .keyword },
            .{ "else", .keyword }, .{ "for", .keyword }, .{ "while", .keyword },
            .{ "switch", .keyword }, .{ "case", .keyword }, .{ "break", .keyword },
            .{ "continue", .keyword }, .{ "class", .keyword }, .{ "extends", .keyword },
            .{ "new", .keyword }, .{ "this", .variable }, .{ "super", .variable },
            .{ "import", .keyword }, .{ "export", .keyword }, .{ "from", .keyword },
            .{ "async", .keyword }, .{ "await", .keyword }, .{ "try", .keyword },
            .{ "catch", .keyword }, .{ "throw", .keyword }, .{ "null", .constant },
            .{ "undefined", .constant }, .{ "true", .constant }, .{ "false", .constant },
            .{ "typeof", .keyword }, .{ "instanceof", .keyword }, .{ "of", .keyword },
            .{ "in", .keyword }, .{ "interface", .type }, .{ "type", .type },
            .{ "enum", .type }, .{ "namespace", .keyword }, .{ "typeof", .keyword },
            .{ "keyof", .keyword }, .{ "any", .type }, .{ "void", .type },
            .{ "never", .type }, .{ "unknown", .type }, .{ "string", .type },
            .{ "number", .type }, .{ "boolean", .type },
        });
        return tokenizeLine(line, keywords);
    }

    fn highlightRust(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "fn", .keyword }, .{ "let", .keyword }, .{ "mut", .keyword },
            .{ "const", .keyword }, .{ "return", .keyword }, .{ "if", .keyword },
            .{ "else", .keyword }, .{ "for", .keyword }, .{ "while", .keyword },
            .{ "loop", .keyword }, .{ "match", .keyword }, .{ "break", .keyword },
            .{ "continue", .keyword }, .{ "struct", .keyword }, .{ "enum", .keyword },
            .{ "impl", .keyword }, .{ "trait", .keyword }, .{ "pub", .keyword },
            .{ "use", .keyword }, .{ "mod", .keyword }, .{ "crate", .keyword },
            .{ "self", .variable }, .{ "super", .variable }, .{ "true", .constant },
            .{ "false", .constant }, .{ "Some", .type }, .{ "None", .constant },
            .{ "Ok", .type }, .{ "Err", .type },
        });
        return tokenizeLine(line, keywords);
    }

    fn highlightHtml(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        var hl = HighlightLine.init(self.allocator);
        var i: usize = 0;
        while (i < line.len) {
            if (line[i] == '<') {
                const end = std.mem.indexOfScalar(u8, line[i+1..], '>') orelse break;
                try hl.addToken(i, i + end + 2, .tag);
                i += end + 2;
            } else {
                const next = std.mem.indexOfScalar(u8, line[i..], '<') orelse (line.len - i);
                try hl.addToken(i, i + next, .unknown);
                i += next;
            }
        }
        if (hl.tokens.items.len == 0 and line.len > 0) {
            try hl.addToken(0, line.len, .unknown);
        }
        return hl;
    }

    fn highlightCss(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        var hl = HighlightLine.init(self.allocator);
        if (line.len > 0) try hl.addToken(0, line.len, .unknown);
        return hl;
    }

    fn highlightJson(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        var hl = HighlightLine.init(self.allocator);
        var i: usize = 0;
        while (i < line.len) {
            if (line[i] == '"') {
                const end = std.mem.indexOfScalar(u8, line[i+1..], '"') orelse (line.len - i - 1);
                try hl.addToken(i, i + end + 2, .string);
                i += end + 2;
            } else if (line[i] >= '0' and line[i] <= '9' or line[i] == '-') {
                var j = i + 1;
                while (j < line.len and (line[j] >= '0' and line[j] <= '9' or line[j] == '.' or line[j] == 'e' or line[j] == 'E' or line[j] == '+' or line[j] == '-')) j += 1;
                try hl.addToken(i, j, .number);
                i = j;
            } else if (std.mem.startsWith(u8, line[i..], "true") or std.mem.startsWith(u8, line[i..], "false") or std.mem.startsWith(u8, line[i..], "null")) {
                try hl.addToken(i, i + 4, .constant);
                i += 4;
            } else {
                i += 1;
            }
        }
        if (hl.tokens.items.len == 0 and line.len > 0) {
            try hl.addToken(0, line.len, .unknown);
        }
        return hl;
    }

    fn highlightMarkdown(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        var hl = HighlightLine.init(self.allocator);
        if (line.len == 0) {
            try hl.addToken(0, 0, .whitespace);
            return hl;
        }
        if (line[0] == '#') {
            try hl.addToken(0, line.len, .markup_heading);
        } else if (std.mem.startsWith(u8, line, "```")) {
            try hl.addToken(0, line.len, .markup_code_block);
        } else if (line[0] == '-' or line[0] == '*' or (line[0] >= '0' and line[0] <= '9')) {
            try hl.addToken(0, line.len, .markup_list);
        } else {
            try hl.addToken(0, line.len, .unknown);
        }
        return hl;
    }

    fn highlightC(self: *SyntaxEngine, line: []const u8) !HighlightLine {
        _ = self;
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "int", .type }, .{ "char", .type }, .{ "float", .type },
            .{ "double", .type }, .{ "void", .type }, .{ "long", .type },
            .{ "short", .type }, .{ "unsigned", .type }, .{ "signed", .type },
            .{ "const", .keyword }, .{ "static", .keyword }, .{ "extern", .keyword },
            .{ "volatile", .keyword }, .{ "struct", .keyword }, .{ "union", .keyword },
            .{ "enum", .keyword }, .{ "typedef", .keyword }, .{ "sizeof", .keyword },
            .{ "if", .keyword }, .{ "else", .keyword }, .{ "for", .keyword },
            .{ "while", .keyword }, .{ "do", .keyword }, .{ "switch", .keyword },
            .{ "case", .keyword }, .{ "break", .keyword }, .{ "continue", .keyword },
            .{ "return", .keyword }, .{ "goto", .keyword }, .{ "NULL", .constant },
            .{ "true", .constant }, .{ "false", .constant },
        });
        return tokenizeLine(line, keywords);
    }
};

fn detectLanguage(ext: []const u8) SyntaxKind {
    const map = std.ComptimeStringMap(SyntaxKind, .{
        .{ ".zig", .zig }, .{ ".rs", .rust }, .{ ".py", .python },
        .{ ".js", .javascript }, .{ ".ts", .typescript }, .{ ".jsx", .javascript },
        .{ ".tsx", .typescript }, .{ ".html", .html }, .{ ".htm", .html },
        .{ ".css", .css }, .{ ".scss", .css }, .{ ".json", .json },
        .{ ".md", .markdown }, .{ ".yaml", .yaml }, .{ ".yml", .yaml },
        .{ ".toml", .toml }, .{ ".c", .c }, .{ ".h", .c },
        .{ ".cpp", .cpp }, .{ ".hpp", .cpp }, .{ ".cc", .cpp },
        .{ ".java", .java }, .{ ".go", .go }, .{ ".rb", .ruby },
        .{ ".php", .php }, .{ ".swift", .swift }, .{ ".kt", .kotlin },
        .{ ".dart", .dart }, .{ ".lua", .lua }, .{ ".sh", .shell },
        .{ ".bash", .shell }, .{ ".sql", .sql },
    });
    return map.get(ext) orelse .text;
}

fn tokenizeLine(line: []const u8, keywords: anytype) !HighlightLine {
    var allocator = std.heap.page_allocator;
    var hl = HighlightLine{ .tokens = std.array_list.Managed(Token).init(allocator), .allocator = allocator };
    var i: usize = 0;
    while (i < line.len) {
        // Skip whitespace
        if (line[i] == ' ' or line[i] == '\t') {
            var j = i + 1;
            while (j < line.len and (line[j] == ' ' or line[j] == '\t')) j += 1;
            try hl.addToken(i, j, .whitespace);
            i = j;
            continue;
        }
        // Comments
        if (std.mem.startsWith(u8, line[i..], "//") or std.mem.startsWith(u8, line[i..], "#")) {
            try hl.addToken(i, line.len, .comment);
            i = line.len;
            continue;
        }
        // Strings
        if (line[i] == '"' or line[i] == '\'') {
            const quote = line[i];
            var j = i + 1;
            while (j < line.len) {
                if (line[j] == '\\') j += 2;
                else if (line[j] == quote) { j += 1; break; }
                else j += 1;
            }
            try hl.addToken(i, j, .string);
            i = j;
            continue;
        }
        // Numbers
        if (line[i] >= '0' and line[i] <= '9') {
            var j = i + 1;
            while (j < line.len and ((line[j] >= '0' and line[j] <= '9') or line[j] == '.' or line[j] == 'x' or line[j] == 'X' or (line[j] >= 'a' and line[j] <= 'f') or (line[j] >= 'A' and line[j] <= 'F'))) j += 1;
            try hl.addToken(i, j, .number);
            i = j;
            continue;
        }
        // Identifiers and keywords
        if ((line[i] >= 'a' and line[i] <= 'z') or (line[i] >= 'A' and line[i] <= 'Z') or line[i] == '_') {
            var j = i + 1;
            while (j < line.len and ((line[j] >= 'a' and line[j] <= 'z') or (line[j] >= 'A' and line[j] <= 'Z') or (line[j] >= '0' and line[j] <= '9') or line[j] == '_')) j += 1;
            const word = line[i..j];
            const token_type = keywords.get(word) orelse .unknown;
            try hl.addToken(i, j, token_type);
            i = j;
            continue;
        }
        // Operators and punctuation
        if (std.mem.startsWith(u8, line[i..], "->") or std.mem.startsWith(u8, line[i..], "=>") or
            std.mem.startsWith(u8, line[i..], "==") or std.mem.startsWith(u8, line[i..], "!=") or
            std.mem.startsWith(u8, line[i..], "<=") or std.mem.startsWith(u8, line[i..], ">=") or
            std.mem.startsWith(u8, line[i..], "||") or std.mem.startsWith(u8, line[i..], "&&")) {
            try hl.addToken(i, i + 2, .operator);
            i += 2;
            continue;
        }
        if (line[i] == '+' or line[i] == '-' or line[i] == '*' or line[i] == '/' or
            line[i] == '=' or line[i] == '<' or line[i] == '>' or line[i] == '!' or
            line[i] == '|' or line[i] == '&' or line[i] == '^' or line[i] == '~' or
            line[i] == '%') {
            try hl.addToken(i, i + 1, .operator);
            i += 1;
            continue;
        }
        if (line[i] == '(' or line[i] == ')' or line[i] == '{' or line[i] == '}' or
            line[i] == '[' or line[i] == ']' or line[i] == ';' or line[i] == ',' or
            line[i] == ':' or line[i] == '.' or line[i] == '?' or line[i] == '@') {
            try hl.addToken(i, i + 1, .punctuation);
            i += 1;
            continue;
        }
        // Fallback
        try hl.addToken(i, i + 1, .unknown);
        i += 1;
    }
    if (hl.tokens.items.len == 0 and line.len > 0) {
        try hl.addToken(0, line.len, .unknown);
    }
    return hl;
}
