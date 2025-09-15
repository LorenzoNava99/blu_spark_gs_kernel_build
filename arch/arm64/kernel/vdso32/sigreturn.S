/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Signal trampolines for returning from a signal when the SA_RESTORER
 * flag is not set. For the vdso32 case we can't use the same names as
 * for the 64-bit case.
 *
 * Copyright (C) 2012 ARM Limited
 */

#include <linux/linkage.h>
#include <asm/unistd32.h>

	.text

SYM_CODE_START(__vdso_sigreturn)
	mov	r7, #__NR_sigreturn
	svc	#0
SYM_CODE_END(__vdso_sigreturn)

SYM_CODE_START(__vdso_rt_sigreturn)
	mov	r7, #__NR_rt_sigreturn
	svc	#0
SYM_CODE_END(__vdso_rt_sigreturn)
