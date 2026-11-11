const shim = @import("shim");

export fn zig_app_setup() void {
    shim.display_begin();
    shim.serial_print("starting!");
}

export fn zig_app_loop() void {
    shim.display_set_cursor(100, 0);
    shim.display_print("hello world");
}
