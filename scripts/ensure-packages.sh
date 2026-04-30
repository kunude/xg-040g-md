#!/bin/bash
set -e

cd openwrt

echo "=== Ensuring Required Packages ==="

# 检查关键包是否存在
check_package() {
    local pkg=$1
    if ! ./scripts/feeds list | grep -q "^${pkg}$"; then
        echo "❌ Package ${pkg} not found in feeds"
        exit 1
    fi
    echo "✅ Package ${pkg} found"
}

# 检查CUPS相关包
check_package cups
check_package libcups
check_package cups-filters

# 检查OpenClash相关包
check_package openclash
check_package luci-app-openclash

# 检查LuCI基础包
check_package luci
check_package luci-ssl

echo "=== All required packages verified ==="
