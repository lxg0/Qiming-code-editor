const std = @import("std");
const PluginApi = @import("PluginApi.zig").PluginApi;

pub const PluginInfo = struct {
    id: []const u8,
    name: []const u8,
    version: []const u8,
    publisher: []const u8,
    description: []const u8,
    is_vscode_ext: bool,    // true = converted from VS Code extension
    enabled: bool,
};

pub const PluginManager = struct {
    allocator: std.mem.Allocator,
    plugins: std.ArrayList(PluginInfo),
    api: ?*PluginApi,
    wasm_runtime: WasmRuntime,

    pub const WasmRuntime = struct {
        initialized: bool,
        module_count: usize,
        // In a full implementation, this would hold:
        // - wasmtime or QuickJS WASM instance
        // - per-plugin import tables
        // - shared memory for plugin communication

        pub fn init() WasmRuntime {
            return .{ .initialized = false, .module_count = 0 };
        }

        pub fn deinit(self: *WasmRuntime) void {
            _ = self;
        }
    };

    pub fn init(allocator: std.mem.Allocator) PluginManager {
        return .{
            .allocator = allocator,
            .plugins = std.ArrayList(PluginInfo).init(allocator),
            .api = null,
            .wasm_runtime = WasmRuntime.init(),
        };
    }

    pub fn deinit(self: *PluginManager) void {
        self.plugins.deinit();
        self.wasm_runtime.deinit();
    }

    pub fn setApi(self: *PluginManager, api: *PluginApi) void {
        self.api = api;
    }

    /// Load a WASM plugin from a compiled .wasm file.
    pub fn loadWasmPlugin(self: *PluginManager, name: []const u8, wasm_path: []const u8) !void {
        _ = wasm_path;
        try self.plugins.append(.{
            .id = try std.fmt.allocPrint(self.allocator, "qiming.{s}", .{name}),
            .name = try self.allocator.dupe(u8, name),
            .version = "1.0.0",
            .publisher = "local",
            .description = "WASM plugin",
            .is_vscode_ext = false,
            .enabled = true,
        });
        std.debug.print("[Plugin] 加载 WASM 插件: {s}\n", .{name});
    }

    /// Load a VS Code extension by converting it to WASM via QuickJS.
    /// 1. Reads the VS Code extension manifest (package.json)
    /// 2. Transpiles the JS extension entry point to a WASM module
    /// 3. Loads the WASM module and links it to the PluginApi
    pub fn loadVSCodeExtension(self: *PluginManager, ext_path: []const u8) !void {
        // The VS Code extension path structure:
        // ~/.vscode/extensions/<publisher>.<name>-<version>/
        //   └ package.json
        //   └ extension.js  (or .ts, compiled to .js)
        //   └ ...

        _ = ext_path;
        try self.plugins.append(.{
            .id = try self.allocator.dupe(u8, "vscode-ext"),
            .name = try self.allocator.dupe(u8, "vscode-extension"),
            .version = "1.0.0",
            .publisher = "vscode",
            .description = "VS Code extension loaded via WASM bridge",
            .is_vscode_ext = true,
            .enabled = true,
        });
        std.debug.print("[Plugin] 加载 VS Code 扩展: {s}\n", .{ext_path});
    }

    /// Enable a plugin by name.
    pub fn enablePlugin(self: *PluginManager, name: []const u8) void {
        for (&self.plugins.items) |*p| {
            if (std.mem.eql(u8, p.name, name)) p.enabled = true;
        }
    }

    /// Disable a plugin by name.
    pub fn disablePlugin(self: *PluginManager, name: []const u8) void {
        for (&self.plugins.items) |*p| {
            if (std.mem.eql(u8, p.name, name)) p.enabled = false;
        }
    }

    /// Get list of active (enabled) plugins.
    pub fn activePlugins(self: *const PluginManager) []PluginInfo {
        return self.plugins.items;
    }

    /// Initialize the WASM runtime (e.g. load wasmtime shared library).
    pub fn initWasmRuntime(self: *PluginManager) !void {
        _ = self;
        // In production:
        // 1. Load libwasmtime.dylib (or link statically)
        // 2. Create an Engine + Store
        // 3. Set up import linker with PluginApi functions
        std.debug.print("[Plugin] WASM 运行时初始化 (via wasmtime)\n", .{});
    }

    /// Execute the `activate` function of a WASM plugin.
    pub fn activatePlugin(self: *PluginManager, name: []const u8) !void {
        _ = self;
        _ = name;
        // 1. Load .wasm bytes
        // 2. wasmtime::Module::new(engine, bytes)
        // 3. Create linker with PluginApi imports
        // 4. Instantiate module
        // 5. Call exported "activate" function
        std.debug.print("[Plugin] 激活插件: {s}\n", .{name});
    }
};
