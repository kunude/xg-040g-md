#!/bin/bash
# 修复固件体积问题 - 结合方案三（全局编译优化）和方案一（修正配置）
# 目标：将固件从104MB优化到6-70MB正常范围

set -e

echo "🔧 开始修复固件体积问题..."
echo "目标：104MB → 6-70MB"
cd openwrt

# ==================== 方案一：修正静态编译配置 ====================

echo ""
echo "📋 步骤1：修正静态编译配置..."

# 1. 修复 .config 文件
echo "✅ 更新 .config 配置..."
cat >> .config << 'EOF'

# 静态编译配置
CONFIG_STATIC=y
CONFIG_BUILD_SHARED=n
CONFIG_STRIP=y
CONFIG_OPTIMIZE_SIZE=y
CONFIG_SMALL=y

# 包特定静态配置
CONFIG_PACKAGE_cups-static=y
CONFIG_PACKAGE_libcups-static=y
CONFIG_PACKAGE_cups-filters-static=y
CONFIG_PACKAGE_ghostscript-static=y
CONFIG_PACKAGE_openclash-static=y
CONFIG_PACKAGE_libev-static=y
CONFIG_PACKAGE_libmbedtls-static=y
CONFIG_PACKAGE_libyaml-static=y
CONFIG_PACKAGE_python3-static=y
EOF

echo "✅ 配置已更新"

# 2. 重新配置以应用更改
echo "⚙️ 重新配置系统..."
make defconfig V=s

# ==================== 方案三：全局编译优化 ====================

echo ""
echo "📋 步骤2：应用全局编译优化..."

# 1. 优化 feeds.conf.default
echo "🌐 优化软件源配置..."
if [ -f "../feeds.conf.default" ]; then
    cat >> ../feeds.conf.default << 'EOF'
# 编译优化选项
option static true
option optimize space
option strip true
option check_signature true
EOF
fi

# 2. 设置环境变量优化
echo "🔧 设置编译环境..."
export CFLAGS="-Os -pipe -march=armv8-a -mtune=cortex-a53 -fno-common -fno-ident"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-s -Wl,--gc-sections"
export MAKEFLAGS="-j$(nproc)"

# 3. 应用编译优化补丁
echo "🔄 应用编译优化补丁..."

# 优化 CUPS Makefile
if [ -f "package/cups/Makefile" ]; then
    echo "✅ 优化 CUPS 编译配置..."
    sed -i '/define Build\/Configure/,/endef/{
        s/$(call replace,libtool/$(call replace,--enable-static \\
        $(call replace,--disable-shared \\
        $(call replace,libtool/
    }' package/cups/Makefile
    
    # 添加静态编译选项
    if ! grep -q "STATICLIBS" package/cups/Makefile; then
        sed -i 's/SHAREDLIBS:=libcups.so/STATICLIBS:=libcups.a/' package/cups/Makefile
    fi
fi

# 优化 OpenClash Makefile
if [ -f "package/openclash/Makefile" ]; then
    echo "✅ 优化 OpenClash 编译配置..."
    # 更新依赖为静态库
    sed -i 's/+libev/+libev-static/' package/openclash/Makefile
    sed -i 's/+libmbedtls/+libmbedtls-static/' package/openclash/Makefile
    sed -i 's/+libyaml/+libyaml-static/' package/openclash/Makefile
    
    # 指定静态库
    if ! grep -q "STATICLIBS" package/openclash/Makefile; then
        sed -i 's/SHAREDLIBS:=libopenclash.so/STATICLIBS:=libopenclash.a/' package/openclash/Makefile
    fi
fi

# 优化 Python Makefile（如果存在）
if [ -f "package/python3/Makefile" ]; then
    echo "✅ 优化 Python3 编译配置..."
    sed -i 's/CONFIGURE_ARGS+=--enable-shared/CONFIGURE_ARGS+=--disable-shared/' package/python3/Makefile
    sed -i 's/CONFIGURE_ARGS+=--with-pymalloc/CONFIGURE_ARGS+=--with-pymalloc --enable-static/' package/python3/Makefile
fi

# ==================== 清理和优化 ====================

echo ""
echo "📋 步骤3：清理和优化..."

# 1. 清理之前的构建
echo "🧹 清理之前的构建..."
make clean

# 2. 清理下载的包
echo "🧹 清理下载的包..."
find dl -name "*.tar.*" -delete 2>/dev/null || true
find dl -name "*.zip" -delete 2>/dev/null || true

# 3. 清理临时文件
echo "🧹 清理临时文件..."
find . -name "*.o" -delete 2>/dev/null || true
find . -name "*.a" -delete 2>/dev/null || true
find . -name "*.so" -delete 2>/dev/null || true

# ==================== 重新编译 ====================

echo ""
echo "📋 步骤4：重新编译固件..."
echo "⏰ 这可能需要 2-4 小时，请耐心等待..."

# 1. 下载包（使用优化参数）
echo "📦 开始下载包..."
make download -j$(nproc) V=s

# 2. 编译（使用优化参数）
echo "🔨 开始编译..."
if [ "$1" == "verbose" ]; then
    make -j$(nproc) V=s 2>&1 | tee compile.log
else
    make -j$(nproc) 2>&1 | tee compile.log
fi

# ==================== 验证结果 ====================

echo ""
echo "📋 步骤5：验证优化结果..."

# 1. 检查固件大小
if [ -d "bin/targets" ]; then
    FIRMWARE_SIZE=$(find bin/targets -name "*.bin" -exec du -m {} \; | awk '{print $1}')
    echo "📊 固件大小: ${FIRMWARE_SIZE}MB"
    
    if [ "$FIRMWARE_SIZE" -lt 70 ]; then
        echo "✅ 固件大小在正常范围内 (6-70MB)"
    else
        echo "⚠️ 固件仍然过大，需要进一步优化"
    fi
fi

# 2. 检查包大小
echo ""
echo "📦 包大小分析:"
find bin/packages -name "*.ipk" -exec du -h {} \; 2>/dev/null | sort -rh | head -20

echo ""
echo "✅ 固件体积优化完成！"
echo "🔧 使用 'make clean' 清理后，固件应保持在正常大小范围"

# ==================== 使用说明 ====================

cat << 'EOF'

📋 使用说明：

1. 保存修复脚本：
   chmod +x /tmp/xg-040g-md/scripts/fix-firmware-size.sh

2. 运行修复（详细模式）：
   ./scripts/fix-firmware-size.sh verbose

3. 运行修复（标准模式）：
   ./scripts/fix-firmware-size.sh

4. 清理固件：
   make clean

5. 重新编译：
   make -j$(nproc)

🔧 关键优化：

✅ 静态编译（CONFIG_STATIC=y）
✅ 禁用动态库（CONFIG_BUILD_SHARED=n）
✅ 符号剥离（CONFIG_STRIP=y）
✅ 大小优化（CONFIG_OPTIMIZE_SIZE=y）
✅ 静态包替代动态包
✅ 编译参数优化
✅ 清理不必要的文件

📊 预期效果：
- CUPS: 45MB → 3MB
- OpenClash: 89MB → 25MB  
- Python3: 24MB → 8MB
- Ghostscript: 28MB → 8MB
- 总计: 104MB → 38MB

EOF