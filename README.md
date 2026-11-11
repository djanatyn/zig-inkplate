zig inkplate
============
proof of concept:
- create a C++ shim with C ABI exports for Inkplate API,
- call those methods from zig source code,
- build xtensa ESP-32 compatible object file from zig code (requires experimental LLVM),
- link to thin C++ wrapper code calling zig implementation


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
