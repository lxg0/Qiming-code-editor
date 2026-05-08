const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "qiming",
        .root_module = root_mod,
    });

    // ── macOS platform ────────────────────────────────────────────────────────
    if (target.result.os.tag == .macos) {
        // System frameworks
        root_mod.linkFramework("Metal", .{});
        root_mod.linkFramework("MetalKit", .{});
        root_mod.linkFramework("QuartzCore", .{});
        root_mod.linkFramework("AppKit", .{});
        root_mod.linkFramework("Foundation", .{});
        root_mod.linkFramework("CoreGraphics", .{});
        root_mod.linkFramework("CoreText", .{});

        // Objective-C bridge (compiled via clang)
        root_mod.addCSourceFile(.{
            .file = b.path("src/platform/macos/qiming_macos_bridge.m"),
            .flags = &.{
                "-fobjc-arc",
                "-fmodules",
                "-mmacosx-version-min=12.0",
            },
        });

        // Need libc for malloc/free in bridge
        root_mod.linkSystemLibrary("c", .{});
    }
    // ─────────────────────────────────────────────────────────────────────────

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Qiming Editor (TUI mode)");
    run_step.dependOn(&run_cmd.step);

    const run_gui_cmd = b.addRunArtifact(exe);
    run_gui_cmd.step.dependOn(b.getInstallStep());
    run_gui_cmd.addArg("--gui");

    const run_gui_step = b.step("run-gui", "Run Qiming Editor (GUI mode)");
    run_gui_step.dependOn(&run_gui_cmd.step);

    const check_step = b.step("check", "Check compilation without running");
    check_step.dependOn(&exe.step);
}
