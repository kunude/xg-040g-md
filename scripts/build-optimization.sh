#!/bin/bash
# Build optimization script for OpenWrt firmware builds

set -euo pipefail

echo "=== OpenWrt Build Optimization ==="

# Configuration
MAX_CCACHE_SIZE="3G"
FREE_DISK_GB=50
MIN_RAM_GB=4

# Check available disk space
check_disk_space() {
    local available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_gb" -lt "$FREE_DISK_GB" ]; then
        echo "❌ Insufficient disk space. Available: ${available_gb}GB, Required: ${FREE_DISK_GB}GB"
        echo "💡 Try running: sudo apt clean && docker system prune -a"
        exit 1
    fi
    echo "✅ Disk space check passed: ${available_gb}GB available"
}

# Check available RAM
check_ram() {
    local total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram_gb" -lt "$MIN_RAM_GB" ]; then
        echo "⚠️  Low RAM detected: ${total_ram_gb}GB (recommended: ${MIN_RAM_GB}GB+)"
        echo "   Build may be slower or fail"
    else
        echo "✅ RAM check passed: ${total_ram_gb}GB available"
    fi
}

# Optimize ccache configuration
optimize_ccache() {
    echo "🔧 Optimizing ccache configuration..."
    mkdir -p "$CCACHE_DIR"

    # Set ccache options
    ccache -M "$MAX_CCACHE_SIZE"
    # Use environment variable for ccache hardlink (compatible with older versions)
    export CCACHE_HARDLINK=true
    ccache --set-config=compress=true
    ccache --set-config=compress_level=9
    ccache --set-config=sloppiness="include_file_mtime,include_file_ctime,time_macros"

    echo "✅ ccache configured with max size: $MAX_CCACHE_SIZE"
}

# Clean up unnecessary files
cleanup_build_area() {
    echo "🧹 Cleaning up build area..."

    # Remove temporary files
    rm -rf /tmp/* /var/tmp/*

    # Clean package caches
    rm -rf /var/lib/apt/lists/*
    rm -rf /var/cache/apt/archives/*.deb

    # Remove object files
    find . -maxdepth 3 -name "*.o" -delete 2>/dev/null || true
    find . -maxdepth 3 -name "*.a" -delete 2>/dev/null || true

    # Clean git directories in feeds
    find feeds -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true

    # Clean downloaded source archives
    find dl -name "*.src.tar.gz" -delete 2>/dev/null || true
    find dl -name "*.orig.tar.gz" -delete 2>/dev/null || true

    echo "✅ Build area cleaned"
}

# Optimize build configuration
optimize_config() {
    echo "⚙️  Optimizing build configuration..."

    # Disable static libraries to reduce size
    sed -i 's/CONFIG_STATIC=y/CONFIG_STATIC=n/' .config || true

    # Ensure shared libraries are preferred
    sed -i 's/CONFIG_BUILD_SHARED=y/CONFIG_BUILD_SHARED=y/' .config || true

    # Enable stripping
    sed -i 's/CONFIG_STRIP=y/CONFIG_STRIP=y/' .config || true
    sed -i 's/CONFIG_STRIP_ALL=y/CONFIG_STRIP_ALL=y/' .config || true

    echo "✅ Build configuration optimized"
}

# Calculate optimal job count
calculate_jobs() {
    local available_mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)

    if [ "$available_mem_gb" -lt 8 ]; then
        echo 2
    elif [ "$available_mem_gb" -lt 16 ]; then
        echo 4
    else
        # Use fewer jobs than cores to prevent memory exhaustion
        echo $((cpu_cores - 1))
    fi
}

# Main optimization function
optimize_build() {
    echo "🎯 Starting build optimization..."

    check_disk_space
    check_ram
    optimize_ccache
    cleanup_build_area
    optimize_config

    local optimal_jobs=$(calculate_jobs)
    echo "📊 Optimal job count calculated: $optimal_jobs"

    echo "=== Optimization completed ==="
    echo "Next steps:"
    echo "1. Run 'make download -j$optimal_jobs'"
    echo "2. Run 'make -j$optimal_jobs'"
    echo "3. Monitor disk space and memory usage"
}

# Run optimization if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    optimize_build
fi