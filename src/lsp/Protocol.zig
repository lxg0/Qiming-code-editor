const std = @import("std");

pub const Position = struct { line: usize, character: usize };

pub const Range = struct { start: Position, end: Position };

pub const Location = struct { uri: []const u8, range: Range };

pub const DiagnosticSeverity = enum { error, warning, information, hint };

pub const Diagnostic = struct {
    range: Range,
    severity: DiagnosticSeverity,
    message: []const u8,
    source: ?[]const u8,
    code: ?[]const u8,
};

pub const CompletionItemKind = enum {
    text, method, function, constructor, field, variable, class,
    interface, module, property, unit, value, enum, keyword,
    snippet, color, file, folder, enum_member, constant, @"struct",
    @"type", parameter, operator,
};

pub const CompletionItem = struct {
    label: []const u8,
    kind: CompletionItemKind,
    detail: ?[]const u8,
    documentation: ?[]const u8,
    insert_text: ?[]const u8,
};

pub const SymbolKind = enum {
    file, module, namespace, package, class, method, property,
    field, constructor, enum, interface, function, variable,
    constant, string, number, boolean, array, object, key,
    null_, enum_member, struct, event, operator, type_parameter,
};

pub const DocumentSymbol = struct {
    name: []const u8,
    kind: SymbolKind,
    range: Range,
    selection_range: Range,
    children: []DocumentSymbol,
};

pub const TextEdit = struct { range: Range, new_text: []const u8 };

pub const CodeAction = struct {
    title: []const u8,
    kind: ?[]const u8,
    edit: ?[]TextEdit,
    command: ?Command,
};

pub const Command = struct {
    title: []const u8,
    command: []const u8,
    arguments: [][]const u8,
};

pub const Hover = struct {
    contents: []const u8,
    range: ?Range,
};

pub const SignatureHelp = struct {
    signatures: []SignatureInformation,
    active_signature: usize,
    active_parameter: usize,
};

pub const SignatureInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
    parameters: []ParameterInformation,
};

pub const ParameterInformation = struct {
    label: []const u8,
    documentation: ?[]const u8,
};
