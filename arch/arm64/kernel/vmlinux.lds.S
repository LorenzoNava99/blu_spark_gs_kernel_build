/* SPDX-License-Identifier: GPL-2.0 */
/*
 * ld script to make ARM Linux kernel
 * taken from the i386 version by Russell King
 * Written by Martin Mares <mj@atrey.karlin.mff.cuni.cz>
 */

#ifdef CONFIG_EFI
#include <asm/efi.h>
#endif

#include <asm-generic/vmlinux.lds.h>
#include <asm/cache.h>
#include <asm/kernel-pgtable.h>
#include <asm/memory.h>
#include <asm/page.h>

#include "image.h"

OUTPUT_ARCH(aarch64)
ENTRY(_text)

jiffies = jiffies_64;

#define HYPERVISOR_TEXT					\
	/*						\
	 * Hypervisor code and data that runs at	\
	 * higher exception levels			\
	 */						\
	__hyp_idmap_text_start = .;			\
	*(.hyp.idmap.text)				\
	__hyp_idmap_text_end = .;			\
	__hyp_text_start = .;				\
	*(.hyp.text)					\
	HYPERVISOR_PERCPU_SECTION			\
	__hyp_rodata_start = .;				\
	*(.hyp.rodata)					\
	__hyp_rodata_end = .;				\
	__hyp_text_end = .;

#define IDMAP_TEXT					\
	. = ALIGN(SZ_4K);				\
	__idmap_text_start = .;				\
	*(.idmap.text)					\
	__idmap_text_end = .;

#ifdef CONFIG_HIBERNATION
#define HIBERNATE_TEXT					\
	. = ALIGN(SZ_4K);				\
	__hibernate_exit_text_start = .;		\
	*(.hibernate_exit.text)				\
	__hibernate_exit_text_end = .;
#else
#define HIBERNATE_TEXT
#endif

#ifdef CONFIG_KEXEC_CORE
#define KEXEC_TEXT					\
	. = ALIGN(SZ_4K);				\
	__relocate_new_kernel_start = .;		\
	*(.kexec_relocate.text)				\
	__relocate_new_kernel_end = .;
#else
#define KEXEC_TEXT
#endif

SECTIONS
{
	/*
	 * XXX: The linker does not define how output sections are
	 * assigned to input sections when there are multiple statements
	 * matching the same input section name.  There is no documented
	 * order of matching.
	 */
	/DISCARD/ : {
		*(.interp .dynamic)
		*(.dynsym .dynstr .hash .gnu.hash)
	}

	. = KIMAGE_VADDR;

	.head.text : {
		_text = .;
		HEAD_TEXT
	}
	ALIGN_FUNCTION();

	/* we want the small data sections together, so single-instruction offsets
	   can access them all, and initialized data all before uninitialized, so
	   we can shorten the on-disk segment size.  */
	.text : ALIGN(SEGMENT_ALIGN) {		/* Real text segment		*/
		_stext = .;			/* Text and read-only data	*/
		IRQENTRY_TEXT
		SOFTIRQENTRY_TEXT
		ENTRY_TEXT
		TEXT_TEXT
		SCHED_TEXT
		CPUIDLE_TEXT
		LOCK_TEXT
		KPROBES_TEXT
		HYPERVISOR_TEXT
		IDMAP_TEXT
		HIBERNATE_TEXT
		KEXEC_TEXT
		*(.gnu.warning)
	}

	. = ALIGN(SEGMENT_ALIGN);
	_etext = .;			/* End of text section */

	/* everything from this point to __init_begin will be marked RO NX */
	RO_DATA(PAGE_SIZE)

	.got : { *(.got) }
	/*
	 * Make sure that the .got.plt is either completely empty or it
	 * contains only the lazy dispatch entries.
	 */
	.got.plt : { *(.got.plt) }
	ASSERT(SIZEOF(.got.plt) == 0 || SIZEOF(.got.plt) == 0x18,
	       "Unexpected GOT/PLT entries detected!")

	/* code sections that are never executed via the kernel mapping */
	.rodata.text : {
		TRAMP_TEXT
		SWAPPER_DIR_SIZE = 3 * PAGE_SIZE;
		. = ALIGN(PAGE_SIZE);
		idmap_pg_dir = .;
		. += SWAPPER_DIR_SIZE;
		idmap_pg_end = .;

#ifdef CONFIG_ARM64_SW_TTBR0_PAN
		. = ALIGN(PAGE_SIZE);
		reserved_pg_dir = .;
		. += PAGE_SIZE;
		reserved_pg_end = .;
#endif
		swapper_pg_dir = .;
		. += PAGE_SIZE;
		swapper_pg_end = .;
	}

	__init_begin = .;
	__inittext_begin = .;

	.init.text : {
		_sinittext = .;
		INIT_TEXT
		_einittext = .;
		. = ALIGN(4);
		__inittext_end = .;
	}

	.exit.text : {
		EXIT_TEXT
	}

	. = ALIGN(16);
	.init.data : {
		INIT_DATA
		INIT_SETUP(16)
		INIT_CALLS
		CON_INITCALL
		INIT_RAM_FS
	}

	.exit.data : {
		EXIT_DATA
	}

	PERCPU_SECTION(L1_CACHE_BYTES)
	HYPERVISOR_PERCPU_SECTION

	__init_end = .;

	_data = .;
	_sdata = .;
	RW_DATA(L1_CACHE_BYTES, PAGE_SIZE, THREAD_ALIGN)

	/*
	 * Data written with the MMU off but read with the MMU on requires
	 * cache lines to be invalidated, discarding up to a Cache Writeback
	 * Granule (CWG) of data from the cache. Keep the section that
	 * requires this type of maintenance to be in its own Cache Writeback
	 * Granule (CWG) area so the cache maintenance operations don't
	 * interfere with adjacent data.
	 */
	.mmuoff.data.write : ALIGN(SZ_2K) {
		__mmuoff_data_start = .;
		*(.mmuoff.data.write)
	}
	. = ALIGN(SZ_2K);
	.mmuoff.data.read : {
		*(.mmuoff.data.read)
		__mmuoff_data_end = .;
	}

	PECOFF_EDATA_PADDING
	__pecoff_data_rawsize = ABSOLUTE(. - __initdata_begin);
	_edata = .;

	BSS_SECTION(0, 0, 0)

	idmap_pg_dir = .;
	. += SWAPPER_DIR_SIZE;
	idmap_pg_end = .;

#ifdef CONFIG_ARM64_SW_TTBR0_PAN
	reserved_pg_dir = .;
	. += PAGE_SIZE;
	reserved_pg_end = .;
#endif
	swapper_pg_dir = .;
	. += PAGE_SIZE;
	swapper_pg_end = .;

	_end = .;

	STABS_DEBUG
	DWARF_DEBUG
	ELF_DETAILS

	DISCARDS
}

/*
 * The HYP init code can't be more than a page long, and should not
 * cross a page boundary.
 */
ASSERT(__hyp_idmap_text_end - (__hyp_idmap_text_start & ~(SZ_4K - 1)) <= SZ_4K,
	"HYP init code too big or misaligned")

/*
 * If padding is applied before .head.text, virt<->phys conversions will fail.
 */
ASSERT(_text == KIMAGE_VADDR, "HEAD is misaligned")

ASSERT(swapper_pg_dir - idmap_pg_dir == IDMAP_DIR_SIZE,
       "IDMAP_DIR_SIZE is misaligned")
