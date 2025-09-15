#!/bin/bash

# Configuration Validation Script for Enhanced Security Testing Kernel

set -e

CONFIG_FILE="arch/arm64/configs/blu_spark_defconfig"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_config() {
    local config_name=$1
    local expected_value=$2
    local description=$3

    if grep -q "^${config_name}=${expected_value}$" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} $description (${config_name}=${expected_value})"
        return 0
    elif grep -q "^# ${config_name} is not set$" "$CONFIG_FILE" && [ "$expected_value" = "n" ]; then
        echo -e "${GREEN}✓${NC} $description (${config_name} disabled)"
        return 0
    else
        echo -e "${RED}✗${NC} $description (${config_name}=${expected_value}) - MISSING"
        return 1
    fi
}

echo "=== Enhanced Security Testing Kernel Configuration Validation ==="
echo

echo "📊 eBPF Capabilities:"
check_config "CONFIG_BPF" "y" "Basic BPF support"
check_config "CONFIG_BPF_SYSCALL" "y" "BPF syscall interface"
check_config "CONFIG_BPF_JIT" "y" "BPF JIT compiler"
check_config "CONFIG_BPF_JIT_ALWAYS_ON" "y" "JIT always enabled"
check_config "CONFIG_BPF_LSM" "y" "BPF Linux Security Module"
check_config "CONFIG_BPF_EVENTS" "y" "BPF events support"

echo
echo "🔍 Tracing & Profiling:"
check_config "CONFIG_KPROBES" "y" "Dynamic kernel probes"
check_config "CONFIG_KRETPROBES" "y" "Return probes"
check_config "CONFIG_UPROBES" "y" "Userspace probes"
check_config "CONFIG_FTRACE" "y" "Function tracer framework"
check_config "CONFIG_FUNCTION_TRACER" "y" "Function tracing"
check_config "CONFIG_FTRACE_SYSCALLS" "y" "Syscall tracing"
check_config "CONFIG_PERF_EVENTS" "y" "Performance events"

echo
echo "🛡️ Security Features:"
check_config "CONFIG_KSU" "y" "KernelSU root solution"
check_config "CONFIG_SECURITY" "y" "Security framework"
check_config "CONFIG_SECCOMP" "y" "Secure computing mode"
check_config "CONFIG_AUDIT" "y" "Audit subsystem"
check_config "CONFIG_USER_NS" "y" "User namespaces"
check_config "CONFIG_NET_NS" "y" "Network namespaces"

echo
echo "🔧 Debugging & Development:"
check_config "CONFIG_DEBUG_FS" "y" "Debug filesystem"
check_config "CONFIG_KALLSYMS" "y" "Kernel symbol table"
check_config "CONFIG_KALLSYMS_ALL" "y" "All kernel symbols"
check_config "CONFIG_DYNAMIC_DEBUG" "y" "Dynamic debug support"
check_config "CONFIG_MAGIC_SYSRQ" "y" "Magic SysRq key"

echo
echo "⚡ Advanced Features:"
check_config "CONFIG_PER_VMA_LOCK" "y" "Per-VMA locking (6.1+)"
check_config "CONFIG_OVERLAY_FS" "y" "Overlay filesystem"
check_config "CONFIG_FUSE_BPF" "y" "FUSE BPF hooks"

echo
echo "📡 Network Security:"
check_config "CONFIG_NETFILTER" "y" "Netfilter framework"
check_config "CONFIG_SECURITY_NETWORK" "y" "Network security hooks"

echo
echo "🔬 Memory Safety (Optional but Recommended):"
if grep -q "CONFIG_KASAN=y" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓${NC} KASAN (Kernel Address Sanitizer)"
else
    echo -e "${YELLOW}⚠${NC} KASAN not enabled (performance impact)"
fi

if grep -q "CONFIG_UBSAN=y" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓${NC} UBSAN (Undefined Behavior Sanitizer)"
else
    echo -e "${YELLOW}⚠${NC} UBSAN not enabled (development feature)"
fi

if grep -q "CONFIG_KCOV=y" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓${NC} KCOV (Kernel coverage)"
else
    echo -e "${YELLOW}⚠${NC} KCOV not enabled (fuzzing support)"
fi

echo
echo "=== Configuration Summary ==="

# Count enabled features
TOTAL_FEATURES=20
ENABLED_FEATURES=$(grep -c "CONFIG_.*=y" "$CONFIG_FILE" || true)

echo "Total kernel configuration options: $(wc -l < "$CONFIG_FILE")"
echo "Enabled features: $ENABLED_FEATURES"

echo
echo -e "${GREEN}✅ Configuration validated for maximum security testing capabilities${NC}"
echo "This kernel build will provide:"
echo "  • Full eBPF with JIT and LSM support"
echo "  • Comprehensive tracing and profiling"
echo "  • KernelSU with SUSFS root hiding"
echo "  • Advanced debugging capabilities"
echo "  • Linux 6.1 Maple Tree VMA compatibility"
echo
echo "🚀 Ready to build with: ./build_enhanced.sh"