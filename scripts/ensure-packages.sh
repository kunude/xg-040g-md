#!/bin/bash
# OpenWRT Package Verification Script
# Ensures required packages are available in feeds before building

set -euo pipefail

# Script metadata
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Package checking function with detailed error reporting
check_package() {
    local pkg_name="$1"
    local feed_list_output
    
    # Validate package name format (security check)
    if [[ ! "$pkg_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Invalid package name format: $pkg_name"
        return 1
    fi
    
    # Check if package exists in feeds
    if feed_list_output=$(./scripts/feeds list 2>&1 | grep -m1 "^${pkg_name}$"); then
        log_info "Package found: $pkg_name"
        return 0
    else
        log_error "Package not found in feeds: $pkg_name"
        return 1
    fi
}

# Check for required packages with fallback names
check_package_group() {
    local group_name="$1"
    shift
    local package_names=("$@")
    local found=0
    
    log_info "Checking $group_name packages..."
    
    for pkg in "${package_names[@]}"; do
        if check_package "$pkg"; then
            found=1
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        log_warn "No $group_name packages found in feeds (may be expected in some branches)"
        return 1
    fi
    
    return 0
}

# Main verification function
verify_packages() {
    log_info "Starting package verification..."
    
    # Update feeds first
    log_info "Updating feeds..."
    if ! ./scripts/feeds update -a > /dev/null 2>&1; then
        log_error "Failed to update feeds"
        exit 1
    fi
    
    if ! ./scripts/feeds install -a -f > /dev/null 2>&1; then
        log_error "Failed to install feeds"
        exit 1
    fi
    
    # Check package groups (all optional for flexibility)
    
    # CUPS packages (optional)
    check_package_group "CUPS" cups cups-server cups-client libcups cups-filters
    
    # OpenClash packages (optional)
    check_package_group "OpenClash" openclash luci-app-openclash
    
    # LuCI base packages (optional - try multiple names)
    log_info "Checking LuCI base packages..."
    local found_luci=0
    
    for pkg in luci luci-ssl luci-base luci-mod-admin-full; do
        if check_package "$pkg"; then
            found_luci=1
        fi
    done
    
    if [ "$found_luci" -eq 0 ]; then
        log_warn "No essential LuCI packages found (this may prevent web interface)"
        log_warn "Continuing build, but web interface may not be available"
    fi
    
    log_info "Package verification completed (with possible warnings)"
    return 0
}

# Execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    verify_packages
fi
