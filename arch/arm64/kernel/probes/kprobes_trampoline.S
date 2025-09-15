/* SPDX-License-Identifier: GPL-2.0 */
/*
 * trampoline entry and return code for kretprobes.
 */

#include <linux/linkage.h>
#include <asm/asm-offsets.h>
#include <asm/assembler.h>

	.text

SYM_CODE_START(__kprobes_trampoline)
	sub	sp, sp, #S_FRAME_SIZE

	stp	x0, x1, [sp, #S_X0]
	stp	x2, x3, [sp, #S_X2]
	stp	x4, x5, [sp, #S_X4]
	stp	x6, x7, [sp, #S_X6]
	stp	x8, x9, [sp, #S_X8]
	stp	x10, x11, [sp, #S_X10]
	stp	x12, x13, [sp, #S_X12]
	stp	x14, x15, [sp, #S_X14]
	stp	x16, x17, [sp, #S_X16]
	stp	x18, x19, [sp, #S_X18]
	stp	x20, x21, [sp, #S_X20]
	stp	x22, x23, [sp, #S_X22]
	stp	x24, x25, [sp, #S_X24]
	stp	x26, x27, [sp, #S_X26]
	stp	x28, x29, [sp, #S_X28]

	mrs	x9, sp_el0
	stp	lr, x9, [sp, #S_LR]

	mrs	x9, elr_el1
	mrs	x10, spsr_el1
	stp	x9, x10, [sp, #S_PC]

	mov	x0, sp
	bl	trampoline_probe_handler

	ldp	x9, x10, [sp, #S_PC]
	msr	elr_el1, x9
	msr	spsr_el1, x10

	ldp	lr, x9, [sp, #S_LR]
	msr	sp_el0, x9

	ldp	x28, x29, [sp, #S_X28]
	ldp	x26, x27, [sp, #S_X26]
	ldp	x24, x25, [sp, #S_X24]
	ldp	x22, x23, [sp, #S_X22]
	ldp	x20, x21, [sp, #S_X20]
	ldp	x18, x19, [sp, #S_X18]
	ldp	x16, x17, [sp, #S_X16]
	ldp	x14, x15, [sp, #S_X14]
	ldp	x12, x13, [sp, #S_X12]
	ldp	x10, x11, [sp, #S_X10]
	ldp	x8, x9, [sp, #S_X8]
	ldp	x6, x7, [sp, #S_X6]
	ldp	x4, x5, [sp, #S_X4]
	ldp	x2, x3, [sp, #S_X2]
	ldp	x0, x1, [sp, #S_X0]

	add	sp, sp, #S_FRAME_SIZE
	eret
SYM_CODE_END(__kprobes_trampoline)
