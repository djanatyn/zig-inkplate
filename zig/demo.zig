const inkplate = @import("inkplate");

export fn zig_app_setup() void {
    inkplate.serial_print("starting!");
    inkplate.display_begin();
    inkplate.display_clear();
}

export fn zig_app_loop() void {
    inkplate.display_set_cursor(100, 0);
    inkplate.display_print("hello world");
    inkplate.display_display();
}
