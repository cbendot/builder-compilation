#!/usr/bin/env bash
# Use tcbuild build script as LLVM Build Script.
git clone https://github.com/cbendot/tcbuild $(pwd)/llvm-tc -b llvm-tc_template    
cd $(pwd)/llvm-tc
bash build-tc.sh
