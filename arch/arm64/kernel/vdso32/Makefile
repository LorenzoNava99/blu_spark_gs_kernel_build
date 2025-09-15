# SPDX-License-Identifier: GPL-2.0
#
# Building a vDSO image for AArch64.
#
# Author: Will Deacon <will.deacon@arm.com>
# Heavily based on the vDSO Makefiles for other archs.
#

# Absolute relocation type $(ARCH_REL_TYPE_ABS) needs to be defined before
# the inclusion of generic Makefile.
ARCH_REL_TYPE_ABS := R_ARM_JUMP_SLOT|R_ARM_GLOB_DAT|R_ARM_ABS32
include $(srctree)/lib/vdso/Makefile

obj-vdso := vgettimeofday.o note.o sigreturn.o

# Build rules
targets := $(obj-vdso) vdso.so vdso.so.dbg vdso.so.raw
obj-vdso := $(addprefix $(obj)/, $(obj-vdso))

# -Bsymbolic has been added for consistency with arm, the compat vDSO and
# potential future proofing if we end up with internal calls to the exported
# routines, as x86 does (see 6f121e548f83 ("x86, vdso: Reimplement vdso.so
# preparation in build-time C")).
ldflags-y := -shared -soname=linux-vdso.so.1 --hash-style=sysv \
	     -Bsymbolic --build-id=sha1 -n

ifdef CONFIG_LD_ORPHAN_WARN
  ldflags-y += --orphan-handling=warn
endif

ldflags-y += -T

ccflags-y := -fno-common -fno-builtin -fno-stack-protector -ffixed-x18
ccflags-y += -DDISABLE_BRANCH_PROFILING -DBUILD_VDSO32

CFLAGS_REMOVE_vgettimeofday.o = $(CC_FLAGS_FTRACE) -Os $(CC_FLAGS_SCS) \
				$(RANDSTRUCT_CFLAGS) $(GCC_PLUGINS_CFLAGS) \
				$(CC_FLAGS_LTO) $(CC_FLAGS_CFI) \
				-Wmissing-prototypes -Wmissing-declarations
KASAN_SANITIZE			:= n
KCSAN_SANITIZE			:= n
UBSAN_SANITIZE			:= n
OBJECT_FILES_NON_STANDARD	:= y
KCOV_INSTRUMENT			:= n

CFLAGS_vgettimeofday.o = -O2 -mcmodel=tiny -fasynchronous-unwind-tables

ifneq ($(c-gettimeofday-y),)
  CFLAGS_vgettimeofday.o += -include $(c-gettimeofday-y)
endif

# Disable gcov profiling for VDSO code
GCOV_PROFILE := n

targets += vdso.lds
CPPFLAGS_vdso.lds += -P -C -U$(ARCH)

# Link rule for the .so file, .lds has to be first
$(obj)/vdso.so.raw: $(obj)/vdso.lds $(obj-vdso) FORCE
	$(call if_changed,vdsold)

$(obj)/vdso.so.dbg: $(obj)/vdso.so.raw $(obj)/vdso.so FORCE
	$(call if_changed,objcopy)

# Strip rule for the .so file
$(obj)/%.so: OBJCOPYFLAGS := -S
$(obj)/%.so: $(obj)/%.so.dbg FORCE
	$(call if_changed,objcopy)

# Generate VDSO offsets using helper script (if needed)
gen-vdsosym := $(srctree)/arch/arm64/kernel/vdso/gen_vdso_offsets.sh
quiet_cmd_vdsosym = VDSOSYM $@
      cmd_vdsosym = $(NM) $< | $(gen-vdsosym) | LC_ALL=C sort > $@

include/generated/vdso32-offsets.h: $(obj)/vdso.so.dbg FORCE
	$(call if_changed,vdsosym)

# Actual build commands
quiet_cmd_vdsold = LD      $@
      cmd_vdsold = $(cmd_ld)

# Install commands for the unstripped file
quiet_cmd_vdso_install = INSTALL $@
      cmd_vdso_install = cp $(obj)/$@.dbg $(MODLIB)/vdso/$@

vdso.so: $(obj)/vdso.so.dbg
	@mkdir -p $(MODLIB)/vdso
	$(call cmd,vdso_install)

vdso_install: vdso.so
