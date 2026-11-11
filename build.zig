const std = @import("std");

pub fn build(b: *std.Build) void {
    // https://ziglang.org/learn/platform-support/xtensa-linux/
    // requires experimental LLVM
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .xtensa,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32 },
    });

    const app = b.addObject(.{
        .name = "zig_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/demo.zig"),
            .target = target,
        }),
    });

    const compile = b.addSystemCommand(&.{
        "arduino-cli",
        "compile",
        "--fqbn",
        "soldered-inkplate-boards:esp32:Inkplate4TEMPERA:UploadSpeed=115200",
        "arduino",
    });
    // compile.setCwd(b.path("."));
    compile.addPrefixedFileArg(
        "--build-property=build.extra_libs=",
        app.getEmittedBin(),
    );

    const firmware = b.step("firmware", "Build the Arduino firmware");
    firmware.dependOn(&compile.step);
}
