const std = @import("std");
const Protocol = @import("Protocol.zig");
const Transport = @import("Transport.zig").Transport;
const CompletionProvider = @import("Completion.zig").CompletionProvider;
const DiagnosticSet = @import("Diagnostic.zig").DiagnosticSet;
const HoverProvider = @import("Hover.zig").HoverProvider;
const GotoProvider = @import("Goto.zig").GotoProvider;

pub const LspClient = struct {
    allocator: std.mem.Allocator,
    transport: Transport,
    server_capabilities: ServerCapabilities,
    initialized: bool,
    completion: CompletionProvider,
    diagnostics: DiagnosticSet,
    hover: HoverProvider,
    goto: GotoProvider,

    pub const ServerCapabilities = struct {
        text_document_sync: usize = 0,
        hover_provider: bool = false,
        completion_provider: bool = false,
        definition_provider: bool = false,
        references_provider: bool = false,
        document_symbol_provider: bool = false,
        workspace_symbol_provider: bool = false,
        code_action_provider: bool = false,
        signature_help_provider: bool = false,
    };

    pub fn init(allocator: std.mem.Allocator) LspClient {
        return LspClient{
            .allocator = allocator,
            .transport = Transport.init(allocator),
            .server_capabilities = .{},
            .initialized = false,
            .completion = CompletionProvider.init(allocator),
            .diagnostics = DiagnosticSet.init(allocator),
            .hover = HoverProvider.init(allocator),
            .goto = GotoProvider.init(allocator),
        };
    }

    pub fn deinit(self: *LspClient) void {
        self.transport.deinit();
        self.completion.deinit();
        self.diagnostics.deinit();
        self.hover.deinit();
        self.goto.deinit();
    }

    pub fn start(self: *LspClient, command: []const u8, args: [][]const u8) !void {
        try self.transport.start(command, args);
        try self.sendInitialize();
        try self.receiveCapabilities();
    }

    fn sendInitialize(self: *LspClient) !void {
        _ = self;
    }

    fn receiveCapabilities(self: *LspClient) !void {
        _ = self;
        self.initialized = true;
    }

    pub fn openDocument(self: *LspClient, uri: []const u8, language: []const u8, text: []const u8) !void {
        _ = self; _ = uri; _ = language; _ = text;
    }

    pub fn changeDocument(self: *LspClient, uri: []const u8, version: usize, text: []const u8) !void {
        _ = self; _ = uri; _ = version; _ = text;
    }

    pub fn requestCompletion(self: *LspClient, uri: []const u8, line: usize, col: usize) !void {
        try self.completion.request(uri, line, col);
    }

    pub fn requestHover(self: *LspClient, uri: []const u8, line: usize, col: usize) !void {
        try self.hover.request(uri, line, col);
    }

    pub fn requestDefinition(self: *LspClient, uri: []const u8, line: usize, col: usize) !void {
        try self.goto.gotoDefinition(uri, line, col);
    }
};
