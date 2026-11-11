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
