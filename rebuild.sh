#!/bin/bash

# Go to LLVM build folder and rebuild it incremetally.
cd build/x86_64-unknown-linux-gnu/llvm/build
DESTDIR="" cmake --build . --target install --config Release -- -j 32

# Copy the compiled shared library to Rust compiler dependencies.
cp ../lib/libLLVM.so.19.1-rust-1.83.0-nightly ../../../host/stage2/lib
