#!/usr/bin/env bash
# Use tcbuild build script as LLVM Build Script.
git lfs migrate import --everything --include="*git"
git lfs migrate import --everything --include="bin/llvm-lto2"
git lfs migrate import --everything --include="bin/bugpoint"
git lfs migrate import --everything --include="bin/opt"
git lfs migrate import --everything --include="bin/clang-15"
git lfs migrate import --everything --include="bin/clang-scan-deps"
git lfs migrate import --everything --include="lib/libclang.so.15.0.0git"
git lfs migrate import --everything --include="bin/clang-repl"
git lfs migrate import --everything --include="bin/lld"
git lfs migrate import --everything --include="lib/libclang-cpp.so.15git"
git clone https://github.com/cbendot/tcbuild $(pwd)/llvm-tc -b llvm-tc    
cd $(pwd)/llvm-tc
bash build-tc.sh
