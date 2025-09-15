/*
 * Linker script for 64-bit vDSO.
 * Adapted from the x86 version.
 */

#include <asm/page.h>

OUTPUT_FORMAT("elf64-littleaarch64", "elf64-bigaarch64", "elf64-littleaarch64")
OUTPUT_ARCH(aarch64)

SECTIONS
{
	PROVIDE(_vdso_data = . - PAGE_SIZE);
	PROVIDE(_timens_data = _vdso_data + PAGE_SIZE);
	. = SIZEOF_HEADERS;

	.hash		: { *(.hash) }			:text
	.gnu.hash	: { *(.gnu.hash) }
	.dynsym		: { *(.dynsym) }
	.dynstr		: { *(.dynstr) }
	.gnu.version	: { *(.gnu.version) }
	.gnu.version_d	: { *(.gnu.version_d) }
	.gnu.version_r	: { *(.gnu.version_r) }

	.note		: { *(.note.*) }		:text	:note

	.dynamic	: { *(.dynamic) }		:text	:dynamic

	.rodata		: {
		*(.rodata*)
		*(.got)
		*(.got.plt)
		*(.plt)
	}						:text

	_etext = .;

	.text		: { *(.text*) }			:text	=0x90909090

	/DISCARD/	: {
		*(.note.GNU-stack)
		*(.data .data.* .gnu.linkonce.d.* .sdata*)
		*(.bss .sbss .dynbss .dynsbss)
	}
}

/*
 * We must supply the ELF program headers explicitly to get just one
 * PT_LOAD segment, and set the flags explicitly to make segments read-only.
 */
PHDRS
{
	text		PT_LOAD		FLAGS(5) FILEHDR PHDRS; /* PF_R|PF_X */
	dynamic		PT_DYNAMIC	FLAGS(4);		/* PF_R */
	note		PT_NOTE		FLAGS(4);		/* PF_R */
}

VERSION
{
	LINUX_2.6.39 {
	global:
		__kernel_rt_sigreturn;
		__kernel_gettimeofday;
		__kernel_clock_gettime;
		__kernel_clock_getres;
	local: *;
	};
}