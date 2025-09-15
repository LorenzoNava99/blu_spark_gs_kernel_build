/*
 * Common module linker script, always used when linking a module.
 * Archs are free to supply their own linker scripts.  ld will
 * combine them automatically.
 */
SECTIONS {
	.plt : { BYTE(0) }
	.init.plt : { BYTE(0) }
	.text.ftrace_trampoline : { *(.text.ftrace_trampoline) }
}
