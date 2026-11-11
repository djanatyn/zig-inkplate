#include "shim.h"
#include <Arduino.h>
#include <Inkplate.h>

static Inkplate display(INKPLATE_1BIT);

extern "C" {
void display_begin() { display.begin(); }
void display_set_cursor(int x, int y) { display.setCursor(x, y); }
void display_print(const char *text) { display.print(text); }
void serial_print(const char *text) { Serial.print(text); }
}
