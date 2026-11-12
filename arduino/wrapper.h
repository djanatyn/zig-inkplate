#ifndef INKPLATE_SHIM_H
#define INKPLATE_SHIM_H

#ifdef __cplusplus
extern "C" {
#endif

void display_begin(void);
void display_display(void);
void display_clear(void);
void display_set_cursor(int x, int y);
void display_print(const char *text);
void serial_print(const char *text);

#ifdef __cplusplus
}
#endif

#endif
