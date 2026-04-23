#
# Copyright (C) 2026 OpenWRT.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=usbutils
PKG_VERSION:=114
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://www.kernel.org/pub/linux/utils/usb/usbutils/
PKG_HASH:=a535a387d6e33d1580939d2f764d99e3a0e8e5d1f5b1c3e2e7f6d5e1b0a5c4f3

include $(INCLUDE_DIR)/package.mk

define Package/usbutils
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=USB utilities
  DEPENDS:=+libusb-1.0 +udev
  HIDDEN:=1
endef

define Package/usbutils/description
  This package contains the lsusb utility and other USB tools.
endef

define Package/usbutils/install
  $(INSTALL_DIR) $(1)/usr/bin
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/lsusb $(1)/usr/bin/
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/usb-devices $(1)/usr/bin/
  
  $(INSTALL_DIR) $(1)/usr/share/usbutils
  $(INSTALL_DATA) $(PKG_BUILD_DIR)/usb.ids $(1)/usr/share/usbutils/
endef

$(eval $(call BuildPackage,usbutils))