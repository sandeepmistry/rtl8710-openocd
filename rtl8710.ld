MEMORY{
	tcm (rwx)    : ORIGIN = 0x1FFF0000, LENGTH = 64k
	ram (rwx)    : ORIGIN = 0x10000000, LENGTH = 448k
}

PROVIDE(STACK_TOP = 0x1FFF0000 + 64k);

SECTIONS{
	.text : { __text_beg__ = . ; *(.vectors*) *(.header) *(.text) *(.text*) *(.rodata) *(.rodata*) *(.glue_7) *(.glue_7t) *(.eh_frame) *(.ARM.extab*) . = ALIGN(4); __text_end__ = . ; } >ram
	.data : { . = ALIGN(4); __data_beg__ = . ; *(.ram_vectors) *(.data) *(.data*) *(.ram_func) . = ALIGN(4); __data_end__ = . ; } >ram
	.bss : { . = ALIGN(4); __bss_beg__ = . ; *(.bss) *(COMMON) . = ALIGN(4); __bss_end__ = . ; } >ram
	__exidx_start = .;
	.ARM.exidx : { ___exidx_start = . ; *(.ARM.exidx*) ; ___exidx_end = . ; } >ram
	__exidx_end = .;
	.ARM.extab : { *(.ARM.extab*) } >ram
	. = ALIGN(4);
	end = .; PROVIDE (end = .);
}

