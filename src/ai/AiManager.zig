const std = @import("std");
const Anthropic = @import("Anthropic.zig").AnthropicProvider;
const OpenAI = @import("OpenAI.zig").OpenAIProvider;
const Ollama = @import("Ollama.zig").OllamaProvider;
const ChatPanel = @import("Chat.zig").ChatPanel;
const Completion = @import("Completion.zig").AiCompletion;

pub const AiBackend = enum { claude, gpt, ollama };

pub const AiManager = struct {
    allocator: std.mem.Allocator,
    backend: AiBackend,
    claude: Anthropic,
    openai: OpenAI,
    ollama: Ollama,
    chat: ChatPanel,
    inline_completion: Completion,
    enabled: bool,

    pub fn init(allocator: std.mem.Allocator) AiManager {
        return AiManager{
            .allocator = allocator,
            .backend = .claude,
            .claude = Anthropic.init(allocator),
            .openai = OpenAI.init(allocator),
            .ollama = Ollama.init(allocator),
            .chat = ChatPanel.init(allocator),
            .inline_completion = Completion.init(allocator),
            .enabled = true,
        };
    }

    pub fn deinit(self: *AiManager) void {
        self.claude.deinit();
        self.openai.deinit();
        self.ollama.deinit();
        self.chat.deinit();
        self.inline_completion.deinit();
    }

    pub fn setBackend(self: *AiManager, backend: AiBackend) void {
        self.backend = backend;
    }

    pub fn toggleChat(self: *AiManager) void {
        self.chat.toggle();
    }

    pub fn requestInlineCompletion(self: *AiManager, prefix: []const u8, suffix: []const u8, language: []const u8) !void {
        try self.inline_completion.requestInline(prefix, suffix, language);
    }
};
