// RISC-V Zisk zkVM optimized memory operations
// Uses CSR instructions to signal memory operations to the zkVM runtime
// These operations are detected by the transpiler and replaced with precompiles

use core::arch::asm;

/// memcpy implementation for Zisk zkVM
/// Uses CSR 0x813 to signal a memcpy operation to the zkVM runtime
/// Arguments: dest in CSR, src and n combined via add x0
#[inline(always)]
pub unsafe fn copy_forward(dest: *mut u8, src: *const u8, n: usize) {
    asm!(
        "csrs 0x813, {dest}",
        "add zero, {src}, {n}",
        dest = in(reg) dest,
        src = in(reg) src,
        n = in(reg) n,
        options(nostack)
    );
}

/// copy_backward for Zisk - same as copy_forward since the zkVM handles it
#[inline(always)]
pub unsafe fn copy_backward(dest: *mut u8, src: *const u8, n: usize) {
    // For zkVM, backward copy is the same - the runtime handles overlap
    copy_forward(dest, src, n);
}

/// memset implementation for Zisk zkVM
/// Uses CSR 0x814 to signal a memset operation to the zkVM runtime
#[inline(always)]
pub unsafe fn set_bytes(s: *mut u8, c: u8, n: usize) {
    asm!(
        "csrs 0x814, {dest}",
        "add zero, {val}, {n}",
        dest = in(reg) s,
        val = in(reg) c as usize,
        n = in(reg) n,
        options(nostack)
    );
}

/// memcmp implementation for Zisk zkVM
/// Uses CSR 0x815 to signal a memcmp operation to the zkVM runtime
/// Returns comparison result
#[inline(always)]
pub unsafe fn compare_bytes(s1: *const u8, s2: *const u8, n: usize) -> i32 {
    let result: i32;
    asm!(
        "csrs 0x815, {s1}",
        "add {result}, {s2}, {n}",
        s1 = in(reg) s1,
        s2 = in(reg) s2,
        n = in(reg) n,
        result = lateout(reg) result,
        options(nostack)
    );
    result
}

/// strlen implementation for Zisk zkVM  
/// Uses CSR 0x816 to signal a strlen operation to the zkVM runtime
#[inline(always)]
pub unsafe fn c_string_length(s: *const core::ffi::c_char) -> usize {
    let result: usize;
    asm!(
        "csrs 0x816, {s}",
        "mv {result}, zero",
        s = in(reg) s,
        result = lateout(reg) result,
        options(nostack)
    );
    result
}
