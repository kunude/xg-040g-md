#
# Copyright (C) 2026 OpenWRT.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=alist
PKG_VERSION:=3.36.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Xhofe/alist/releases/download/v$(PKG_VERSION)/
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/alist
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Alist file listing service
  URL:=https://github.com/Xhofe/alist
  MAINTAINER:=OpenWRT Team <openwrt@openwrt.org>
endef

define Package/alist/description
  Alist is a file listing program that can work as a web service.
  It supports multiple storage backends and provides a web interface.
endef

define Package/alist/install
  $(INSTALL_DIR) $(1)/usr/bin
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/alist $(1)/usr/bin/
  
  $(INSTALL_DIR) $(1)/etc/alist
  $(INSTALL_CONF) $(PKG_BUILD_DIR)/config.json $(1)/etc/alist/
  
  $(INSTALL_DIR) $(1)/etc/init.d
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/alist.init $(1)/etc/init.d/alist
endef

$(eval $(call BuildPackage,alist))

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-alist
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Alist Web UI
  DEPENDS:=+alist +luci-base
  PKGARCH:=all
endef

define Package/luci-app-alist/description
  LuCI interface for Alist file listing service.
endef

define Package/luci-app-alist/install
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
  
  $(INSTALL_DATA) ./luasrc/controller/alist.lua $(1)/usr/lib/lua/luci/controller/
  $(INSTALL_DATA) ./luasrc/model/cbi/alist.lua $(1)/usr/lib/lua/luci/model/cbi/
  $(INSTALL_DATA) ./luasrc/view/alist/*.htm $(1)/usr/lib/lua/luci/view/alist/
  
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
  $(INSTALL_DATA) ./po/zh-cn/alist.po $(1)/usr/lib/lua/luci/i18n/alist.zh-cn.po
endef

$(eval $(call BuildPackage,luci-app-alist))