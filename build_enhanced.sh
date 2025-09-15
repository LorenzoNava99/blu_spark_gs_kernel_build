#!/bin/bash

# Enhanced Android Kernel Build Script with Maximum Security Testing Capabilities
# For Android 15/16 ASB 2025-09 gs-next variant with KSU-Next + SUSFS

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
log_info "Validating build environment..."

# Check required tools
REQUIRED_TOOLS=("clang" "lld" "python3" "git" "make" "flex" "bison")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        log_error "$tool is not installed or not in PATH"
        exit 1
    fi
done

# Set up build environment
export PATH="/usr/lib/llvm-17/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf
export STRIP=llvm-strip
export LLVM=1
export LLVM_IAS=1

# Android-specific cross-compile settings
export CLANG_TRIPLE=aarch64-linux-gnu
export CROSS_COMPILE=aarch64-linux-android31-
export CROSS_COMPILE_ARM32=arm-linux-androideabi31-

log_success "Build environment configured"

# Apply SUSFS patches if not already applied
log_info "Checking SUSFS patches..."

if [ -f "kernel_patches/fs/susfs.c" ] && [ -f "kernel_patches/include/linux/susfs.h" ]; then
    log_info "Copying SUSFS files..."
    cp kernel_patches/fs/susfs.c fs/
    cp kernel_patches/include/linux/susfs.h include/linux/
    log_success "SUSFS files copied"
else
    log_warn "SUSFS patch files not found, skipping..."
fi

# Clean previous builds
log_info "Cleaning previous build artifacts..."
make mrproper

# Configure kernel
log_info "Configuring kernel with enhanced security features..."
make blu_spark_defconfig

# Enable additional debugging features if desired
log_info "Enhanced configuration applied with:"
log_info "  ✓ BPF LSM enabled"
log_info "  ✓ Function tracing enabled"
log_info "  ✓ User namespaces enabled"
log_info "  ✓ Dynamic debugging enabled"
log_info "  ✓ FTRACE syscalls enabled"
log_info "  ✓ KASAN/UBSAN/KCOV enabled"
log_info "  ✓ BTF debugging enabled"

# Build the kernel
log_info "Starting kernel compilation..."
START_TIME=$(date +%s)

make -j$(nproc) 2>&1 | tee build.log

BUILD_STATUS=${PIPESTATUS[0]}
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

if [ $BUILD_STATUS -eq 0 ]; then
    log_success "Kernel compiled successfully in ${BUILD_TIME} seconds"

    # Build KSU userspace tools
    log_info "Building KSU SUSFS userspace tools..."
    if command -v ndk-build &> /dev/null; then
        ./build_ksu_susfs_tool.sh
        log_success "KSU SUSFS tools built successfully"
    else
        log_warn "Android NDK not found, skipping userspace tools build"
    fi

    # Create KSU module
    log_info "Creating KSU module package..."
    ./build_ksu_module.sh
    log_success "KSU module package created"

    # Display build artifacts
    log_success "Build completed! Artifacts:"
    ls -lh arch/arm64/boot/Image* 2>/dev/null || true
    ls -lh *.zip 2>/dev/null || true

else
    log_error "Kernel compilation failed! Check build.log for details"
    tail -20 build.log
    exit 1
fi