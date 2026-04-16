OUTPUT_FORMAT("elf64-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  rom   (xa) : ORIGIN = 0x80000000, LENGTH = 0x10000000
  ram   (wxa) : ORIGIN = 0xa0000000, LENGTH = 0x20000000
}

PHDRS {
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
  bss PT_LOAD FLAGS(6);
  output_data PT_LOAD FLAGS(6);
  general_registers_data PT_LOAD FLAGS(6);
  float_registers_data PT_LOAD FLAGS(6);
}

_stack_size                  = 0x400000;  /* 4 MB reserved */
_general_registers_data_size = 0x8000;    /* 32 kB */
_float_registers_data_size   = 0x8000;    /* 32 kB */
_output_data_size            = 0x20000;   /* 128 KB reserved */
_float_ram_data_size         = 0x10000;   /* 64 KB reserved */

/*

0xA000_0000  ┌────────────────────┐← _init_stack_bottom
             │                    │
             │   stack ↑ 4MB      │
             │                    │
0xA040_0000  ├────────────────────┤← _init_stack_top
             │ .general_registers │  32 KB reserved (NOLOAD)
             │  0x8000 bytes      │  _general_registers_data_start / _end
0xA040_8000  ├────────────────────┤
             │ .float_registers   │  32 KB reserved (NOLOAD)
             │  0x8000 bytes      │  _float_registers_data_start / _end
0xA041_0000  ├────────────────────┤
             │ .output_data       │  128 KB reserved (NOLOAD)
             │  0x20000 bytes     │  _output_data_start / _end
0xA043_0000  ├────────────────────┤
             │   .data            │
             │   .bss             │
             ├────────────────────┤ ← _bss_end, _kernel_heap_bottom
             │   heap ↓           │
             │                    │
             │                    │
             │                    │
             │                    │
0xBFFF_0000  ├────────────────────┤ ← _kernel_heap_top 
             │ float ram          │
0xC000_0000  └────────────────────┘

*/

SECTIONS
{
  .text : { *(.text.init) *(.text .text.*)} >rom AT>rom :text

  . = ALIGN(8);
  PROVIDE(_global_pointer = .);
  .rodata : { *(.rodata .rodata.*)} >rom AT>rom :rodata

  /* reserve stack at the beginning of RAM */
  . = ORIGIN(ram);
  PROVIDE(_stack_start = .);
  . = . + _stack_size;
  PROVIDE(_init_stack_top = .); # reserve 4M bytes for the initialisation stack

  /* reserved space for general registers */

  .general_registers_data (NOLOAD) : {
    PROVIDE(_general_registers_data_start = .);
    . = . + _general_registers_data_size; 
    PROVIDE(_general_registers_data_end = .);
  } >ram AT>ram :general_registers_data

  /* reserved space for float registers */

  .float_registers_data (NOLOAD) : {
    PROVIDE(_float_registers_data_start = .);
    . = . + _float_registers_data_size; 
    PROVIDE(_float_registers_data_end = .);
  } >ram AT>ram :float_registers_data

  /* reserved space for output data */

  .output_data (NOLOAD) : {
    PROVIDE(_output_data_start = .);
    . = . + _output_data_size; 
    PROVIDE(_output_data_end = .);
  } >ram AT>ram :output_data

  .data : { *(.data .data.* .sdata .sdata.*) } >ram AT>ram :data

  .bss : {
    PROVIDE(_bss_start = .);
    *(.bss .bss.*);
    PROVIDE(_bss_end = .); # ... and one at the end
  } >ram AT>ram :bss

  PROVIDE(_kernel_heap_bottom = .);
  PROVIDE(_kernel_heap_top = ORIGIN(ram) + LENGTH(ram) - _float_ram_data_size);
  PROVIDE(_kernel_heap_size = _kernel_heap_top - _kernel_heap_bottom);

  _end = .;
}