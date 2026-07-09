OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH(i386)

SECTIONS
{
    /* ブートローダ（512バイト）は 0x7C00 に配置 */
    . = 0x7C00;
    .boot : {
        boot.o(.text)
    }

    /* カーネル（C言語）は、その直後の 0x7E00 から配置 */
    . = 0x7E00;
    .text : {
        *(.text)
    }
    .rodata : { *(.rodata*) }
    .data   : { *(.data) }
    .bss    : { *(.bss) }
}