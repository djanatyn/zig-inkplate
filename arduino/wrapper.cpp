#include "wrapper.h"
#include <Arduino.h>
#include <Inkplate.h>

static Inkplate display(INKPLATE_1BIT);

extern "C" {
void display_begin() {
  display.begin();
  display.frontlight.setState(true);
  display.frontlight.setBrightness(5);
  display.setTextSize(2);
  display.setTextColor(BLACK);
}
void display_display() { display.display(); }
void display_clear() { display.clearDisplay(); }
void display_set_cursor(int x, int y) { display.setCursor(x, y); }
void display_print(const char *text) { display.print(text); }
void serial_print(const char *text) { Serial.print(text); }
}
