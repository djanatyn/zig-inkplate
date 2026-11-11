const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .xtensa,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32 },
    });

    const optimize: std.builtin.Optimize = .Debug;

    const translated_shim = b.addTranslateC(.{
        .root_source_file = b.path("arduino/shim.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });

    const app_module = b.createModule(.{
        .root_source_file = b.path("zig/demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "shim",
                .module = translated_shim.createModule(),
            },
        },
    });

    const app = b.addObject(.{
        .name = "zig_app",
        .root_module = app_module,
    });

    const compile = b.addSystemCommand(&.{
        "arduino-cli",
        "compile",
        "--fqbn",
        "soldered-inkplate-boards:esp32:Inkplate4TEMPERA:UploadSpeed=115200",
        "arduino",
    });
    compile.addPrefixedFileArg(
        "--build-property=build.extra_libs=",
        app.getEmittedBin(),
    );
    compile.step.dependOn(&app.step);

    const firmware = b.step("firmware", "Build the Arduino firmware");
    firmware.dependOn(&compile.step);
}
