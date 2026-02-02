#!/bin/bash
# Script to apply patches to LLVM before building
# Patches are stored in src/llvm-patches/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLVM_DIR="$SCRIPT_DIR/src/llvm-project"
PATCHES_DIR="$SCRIPT_DIR/src/llvm-patches"

cd "$SCRIPT_DIR"

# If a specific patch file is provided, use it
if [ -n "$1" ]; then
    PATCH_FILES=("$1")
else
    # Otherwise, apply all patches from src/llvm-patches/
    if [ ! -d "$PATCHES_DIR" ]; then
        echo "Error: Patches directory does not exist: $PATCHES_DIR"
        exit 1
    fi
    
    PATCH_FILES=("$PATCHES_DIR"/*.patch)
    
    if [ ! -e "${PATCH_FILES[0]}" ]; then
        echo "No patch files found in $PATCHES_DIR"
        exit 0
    fi
fi

echo "Applying patches to LLVM..."
cd "$LLVM_DIR"

APPLIED=0
for PATCH_FILE in "${PATCH_FILES[@]}"; do
    if [ ! -f "$PATCH_FILE" ]; then
        echo "Warning: Patch file does not exist: $PATCH_FILE"
        continue
    fi
    
    PATCH_NAME=$(basename "$PATCH_FILE")
    
    # Check if patch can be applied
    if git apply --check "$PATCH_FILE" 2>/dev/null; then
        echo "  Applying: $PATCH_NAME"
        git apply "$PATCH_FILE"
        APPLIED=$((APPLIED + 1))
    else
        echo "  Skipping: $PATCH_NAME (already applied or conflicts)"
    fi
done

if [ $APPLIED -gt 0 ]; then
    git add .
    git commit -m "Apply Zisk LLVM patches ($APPLIED patches)"
    echo "✓ $APPLIED patch(es) applied successfully"
else
    echo "⚠ No new patches were applied"
fi

echo ""
echo "You can now run: ./x.py build --stage 2 compiler/rustc library"
