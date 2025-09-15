/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Signal trampolines for returning from a signal when the SA_RESTORER
 * flag is not set.
 *
 * Copyright (C) 2012 ARM Limited
 */

#include <linux/linkage.h>
#include <asm/unistd.h>

	.text

SYM_CODE_START(__kernel_rt_sigreturn)
	mov	x8, #__NR_rt_sigreturn
	svc	#0
SYM_CODE_END(__kernel_rt_sigreturn)