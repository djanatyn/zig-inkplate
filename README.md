zig inkplate
============
proof of concept:
- create a C++ shim with C ABI exports for Inkplate API,
- call those methods from zig source code,
- build xtensa ESP-32 compatible object file from zig code (requires experimental LLVM),
- link to thin C++ wrapper code calling zig implementation

```objdump
.zig-cache/o/5f912dd94a9e520a84b289cbed9afd69/zig_app.o:     file format elf32-xtensa-le


Disassembly of section .text:

00000000 <zig_app_loop>:
   0:	004136        	entry	a1, 32
   3:	207110        	or	a7, a1, a1
   6:	ffff81        	l32r	a8, 4 <zig_app_loop+0x4> (ff812071 <Target.xtensa.cpu.esp32+0xff811d11>)
			6: R_XTENSA_SLOT0_OP	.literal
   9:	64a0a2        	movi	a10, 100
   c:	00a0b2        	movi	a11, 0
   f:	0008e0        	callx8	a8
  12:	ffffa1        	l32r	a10, 10 <zig_app_loop+0x10> (ffa10008 <Target.xtensa.cpu.esp32+0xffa0fca8>)
			12: R_XTENSA_SLOT0_OP	.literal+0x4
  15:	ffff81        	l32r	a8, 14 <zig_app_loop+0x14> (ffff81ff <Target.xtensa.cpu.esp32+0xffff7e9f>)
			15: R_XTENSA_SLOT0_OP	.literal+0x8
  18:	0008e0        	callx8	a8
  1b:	f01d      	retw.n
  1d:	0020f0        	nop

00000020 <zig_app_setup>:
  20:	004136        	entry	a1, 32
  23:	207110        	or	a7, a1, a1
  26:	ffff81        	l32r	a8, 24 <zig_app_setup+0x4> (ff812071 <Target.xtensa.cpu.esp32+0xff811d11>)
			26: R_XTENSA_SLOT0_OP	.literal+0xc
  29:	0008e0        	callx8	a8
  2c:	0000a1        	l32r	a10, fffc002c <Target.xtensa.cpu.esp32+0xfffbfccc>
			2c: R_XTENSA_SLOT0_OP	.literal+0x10
  2f:	ffff81        	l32r	a8, 2c <zig_app_setup+0xc> (810000a1 <Target.xtensa.cpu.esp32+0x80fffd41>)
			2f: R_XTENSA_SLOT0_OP	.literal+0x14
  32:	0008e0        	callx8	a8
  35:	f01d      	retw.n

Disassembly of section .literal:

00000000 <.literal>:
	...
			0: R_XTENSA_32	display_set_cursor
			4: R_XTENSA_32	.rodata.str1.1
			8: R_XTENSA_32	display_print
			c: R_XTENSA_32	display_begin
			10: R_XTENSA_32	.rodata.str1.1+0xc
			14: R_XTENSA_32	serial_print
```

```objdump
$ xtensa-esp32-elf-objdump -df build/arduino.ino.elf | grep '<zig_app_loop>:' -A 12
400dc53c <zig_app_loop>:
400dc53c:	004136        	entry	a1, 32
400dc53f:	207110        	or	a7, a1, a1
400dc542:	d0f681        	l32r	a8, 400d091c <_stext+0x8fc> (400d2784 <display_set_cursor>)
400dc545:	64a0a2        	movi	a10, 100
400dc548:	00a0b2        	movi	a11, 0
400dc54b:	0008e0        	callx8	a8
400dc54e:	d0f4a1        	l32r	a10, 400d0920 <_stext+0x900> (3f401bd8 <__anon_1059>)
400dc551:	d0f481        	l32r	a8, 400d0924 <_stext+0x904> (400d2794 <display_print>)
400dc554:	0008e0        	callx8	a8
400dc557:	f01d      	retw.n
400dc559:	0020f0        	nop

$ strings -t x build/arduino.ino.elf | grep "hello world"
2bd8 hello world
```

uploading firmware
==================

```
$ zig build -Dport=/dev/cu.usbserial-210 upload
...
Connected to ESP32 on /dev/cu.usbserial-210:
Chip type:          ESP32-D0WD-V3 (revision v3.1)
Features:           Wi-Fi, BT, Dual Core + LP Core, 240MHz, Vref calibration in eFuse, Coding Scheme None
Crystal frequency:  40MHz
MAC:                e8:6b:ea:fb:dc:c0

Stub flasher running.

Configuring flash size...
Flash will be erased from 0x00001000 to 0x00007fff...
Flash will be erased from 0x00008000 to 0x00008fff...
Flash will be erased from 0x0000e000 to 0x0000ffff...
Flash will be erased from 0x00010000 to 0x000fcfff...
Compressed 25184 bytes to 16079...
Writing at 0x00001000 [                              ]   0.0% 0/160
...
Writing at 0x000f6f45 [============================> ]  97.5% 58982
Wrote 968512 bytes (605189 compressed) at 0x00010000 in 58.9 seconds (131.5 kbit/s).
Hash of data verified.

Hard resetting via RTS pin...
```

challenges
==========
- xtensa support is tier 4 for zig, requiring an experimental LLVM backend to generate machine code
- compilation fails on a mysterious "fixup value must be 4-byte aligned" error in all optimization modes:
```
~/code/zig-inkplate: ~/code/zig/build/stage3/bin/zig build firmware
firmware
└─ run arduino-cli
   └─ compile obj zig_app debug xtensa-freestanding-none failure
error: error: <unknown>:0: fixup value must be 4-byte aligned


error: process exited with code 1
failed command: /Users/jstrickland/code/zig/build/stage3/bin/zig build-obj -target xtensa-freestanding-none -mcpu esp32 -Mroot=zig/demo.zig --cache-dir .zig-cache --global-cache-dir /Users/jstrickland/.cache/zig --build-root . --name zig_app --zig-lib-dir /Users/jstrickland/code/zig/build/stage3/lib/zig/ --listen=-

Build Summary: 0/3 steps succeeded (1 failed)
firmware transitive failure
└─ run arduino-cli transitive failure
   └─ compile obj zig_app debug xtensa-freestanding-none failure
```

llvm patch to fix:
```diff
diff --git a/llvm/lib/Target/Xtensa/MCTargetDesc/XtensaTargetStreamer.cpp b/llvm/lib/Target/Xtensa/MCTargetDesc/XtensaTargetStreamer.cpp
index 0ea70cff4..1dbc36f8a 100644
--- a/llvm/lib/Target/Xtensa/MCTargetDesc/XtensaTargetStreamer.cpp
+++ b/llvm/lib/Target/Xtensa/MCTargetDesc/XtensaTargetStreamer.cpp
@@ -90,6 +90,7 @@ void XtensaTargetELFStreamer::emitLiteral(MCSymbol *LblSym, const MCExpr *Value,

     MCSection *ConstSection = Context.getELFSection(
         SectionName, ELF::SHT_PROGBITS, ELF::SHF_EXECINSTR | ELF::SHF_ALLOC);
+    ConstSection->setAlignment(Align(4));

     OutStreamer.pushSection();
     OutStreamer.switchSection(ConstSection);
@@ -112,6 +113,7 @@ void XtensaTargetELFStreamer::startLiteralSection(MCSection *BaseSection) {
       SectionName, ELF::SHT_PROGBITS, ELF::SHF_EXECINSTR | ELF::SHF_ALLOC);

   ConstSection->setAlignment(Align(4));
+  getStreamer().switchSection(ConstSection);
 }

 MCELFStreamer &XtensaTargetELFStreamer::getStreamer() {
diff --git a/llvm/test/MC/Xtensa/directive-literal.s b/llvm/test/MC/Xtensa/directive-literal.s
index 269cf20ed..1dd9c252d 100644
--- a/llvm/test/MC/Xtensa/directive-literal.s
+++ b/llvm/test/MC/Xtensa/directive-literal.s
@@ -21,6 +21,7 @@ test_literal:

 # CHECK-LITERAL: Section {
 # CHECK-LITERAL:   Name: .literal
+# CHECK-LITERAL:   AddressAlignment: 4
 # CHECK-LITERAL:   SectionData (
 # CHECK-LITERAL:     0000: 78563412 00000000 30750000
 # CHECK-LITERAL:   )
@@ -39,4 +40,3 @@ test_literal:
 # CHECK-INST: l32r a4, .Ltmp0
 # CHECK-INST: movi a5, 1000
 # CHECK-INST: ret
-
```

`

setup
=====
compiling llvm with experimental xtensa support:
```bash
# adapted from https://codeberg.org/ziglang/zig#release LLVM build instructions
# https://github.com/llvm/llvm-project
# checkout release/22.x branch
mkdir build && cd build 
cmake ../llvm -G Ninja \
  -DCMAKE_INSTALL_PREFIX=$HOME/local/llvm22-xtensa \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="lld;clang" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Xtensa \
  -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_PARALLEL_LINK_JOBS=1
```

installing zig using experimental LLVM:
```bash
# in a zig checkout:
git checkout 0.17.1
mkdir build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$HOME/local/llvm22-xtensa \
  -DZIG_EXTRA_BUILD_ARGS="-Dllvm-has-xtensa"
cmake --build . --parallel
```
