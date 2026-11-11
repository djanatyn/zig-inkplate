pub extern fn display_begin() void;
pub extern fn display_set_cursor(x: c_int, y: c_int) void;
pub extern fn display_print(text: [*:0]const u8) void;
pub extern fn serial_print(text: [*:0]const u8) void;

export fn zig_app_setup() void {
    serial_print("starting!");
}

export fn zig_app_loop() void {
    display_set_cursor(100, 100);
    display_print("hello world");
}
