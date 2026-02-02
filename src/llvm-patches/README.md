# LLVM Patches for Zisk Target

This directory contains patches that need to be applied to the LLVM submodule
before building the Rust toolchain.

## How to apply patches

Run from the repository root:

```bash
./apply-llvm-patches.sh
```

Or manually:

```bash
cd src/llvm-project
for patch in ../llvm-patches/*.patch; do
    git apply "$patch"
done
git add .
git commit -m "Apply Zisk LLVM patches"
```

## Patches

- `0001-riscv-processor-zisk.patch` - Custom RISC-V processor definitions for Zisk target

## Notes

- Make sure `submodules = "if-unchanged"` is set in `config.toml`
- After applying patches, LLVM will not be auto-updated by the build system
