const std = @import("std");

fn arduinoCompile(
    b: *std.Build,
    app: *std.Build.Step.Compile,
    upload: bool,
    port: ?[]const u8,
) *std.Build.Step {
    const cmd = b.addSystemCommand(&.{
        "arduino-cli",
        "compile",
        "--fqbn",
        "soldered-inkplate-boards:esp32:Inkplate4TEMPERA:UploadSpeed=115200",
        "--output-dir",
        "build",
        "arduino",
    });
    if (upload) {
        cmd.addArgs(&.{"--upload"});
        if (port) |p| cmd.addArgs(&.{ "-p", p });
    }
    cmd.addPrefixedFileArg(
        "--build-property=build.extra_libs=",
        app.getEmittedBin(),
    );
    cmd.step.dependOn(&app.step);
    return &cmd.step;
}

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .xtensa,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32 },
    });

    const optimize: std.builtin.Optimize = .Debug;

    const inkplate = b.addTranslateC(.{
        .root_source_file = b.path("arduino/wrapper.h"),
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
                .name = "inkplate",
                .module = inkplate.createModule(),
            },
        },
    });

    const app = b.addObject(.{
        .name = "zig_app",
        .root_module = app_module,
    });

    const port = b.option(
        []const u8,
        "port",
        "Serial port for upload/monitor (e.g. /dev/cu.usbserial-1410)",
    );

    const firmware = b.step("firmware", "Build the Arduino firmware");
    firmware.dependOn(arduinoCompile(b, app, false, port));

    const upload = b.step("upload", "Compile and upload over USB");
    upload.dependOn(arduinoCompile(b, app, true, port));

    const monitor_cmd = b.addSystemCommand(&.{
        "arduino-cli", "monitor", "-p", port orelse "", "--config", "115200",
    });
    monitor_cmd.step.dependOn(upload);

    const flash = b.step("flash", "Upload, then open the serial monitor");
    flash.dependOn(&monitor_cmd.step);
}
