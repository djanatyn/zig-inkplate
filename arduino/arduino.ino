#include "<Arduino.h>"
#include "shim.cpp"

extern "C" void zig_app_setup();
extern "C" void zig_app_loop();

void setup() {
  Serial.begin(115200);
  zig_app_setup();
}

void loop() { zig_app_loop() }
