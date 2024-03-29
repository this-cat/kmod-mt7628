# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=mt7628
PKG_VERSION:=4.14

PKG_KCONFIG:=RALINK_MT7628 \
	MT_WIFI MT_WIFI_PATH FIRST_IF_EEPROM_PROM FIRST_IF_EEPROM_EFUSE \
	FIRST_IF_EEPROM_FLASH RT_FIRST_CARD_EEPROM RT_SECOND_CARD_EEPROM \
	MULTI_INF_SUPPORT WIFI_BASIC_FUNC WSC_INCLUDED WSC_V2_SUPPORT \
	DOT11N_DRAFT3 DOT11W_PMF_SUPPORT LLTD_SUPPORT QOS_DLS_SUPPORT \
	WAPI_SUPPORT IGMP_SNOOP_SUPPORT BLOCK_NET_IF RATE_ADAPTION \
	NEW_RATE_ADAPT_SUPPORT AGS_SUPPORT IDS_SUPPORT WIFI_WORKQUEUE \
	WIFI_SKB_RECYCLE LED_CONTROL_SUPPORT ATE_SUPPORT MEMORY_OPTIMIZATION \
	UAPSD RLT_MAC RLT_BBP RLT_RF RTMP_MAC RTMP_BBP RTMP_RF RTMP_PCI_SUPPORT \
	RTMP_USB_SUPPORT RTMP_RBUS_SUPPORT WIFI_MODE_AP WIFI_MODE_STA \
	WIFI_MODE_BOTH 	MT_AP_SUPPORT WDS_SUPPORT MBSS_SUPPORT \
	NEW_MBSSID_MODE ENHANCE_NEW_MBSSID_MODE APCLI_SUPPORT \
	MAC_REPEATER_SUPPORT CON_WPS_SUPPORT LLTD_SUPPORT COC_SUPPORT MT_MAC SNIFFER_SUPPORT 
PKG_CONFIG_DEPENDS:=$(foreach c, $(PKG_KCONFIG),$(if $(CONFIG_$c),CONFIG_$(c)))

include $(INCLUDE_DIR)/package.mk

TAR_CMD=$(HOST_TAR) -C $(1)/ $(TAR_OPTIONS)

define KernelPackage/$(PKG_NAME)
  CATEGORY:=MTK Properties
  TITLE:=MTK MT7628 wifi AP driver
  FILES:=$(PKG_BUILD_DIR)/build/$(PKG_NAME).ko
  DEPENDS:=@TARGET_ramips_mt76x8 +mtk-basefiles +wireless-tools +uci2dat
  SUBMENU:=Drivers
  MENU:=1
endef

define KernelPackage/$(PKG_NAME)/config
	source "$(SOURCE)/config.in"
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -r ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" V=1 \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)/build/" \
		$(foreach c, $(PKG_KCONFIG),$(if $(CONFIG_MT7628_$c),CONFIG_$(c)=$(CONFIG_MT7628_$(c))))\
		CONFIG_RALINK_MT7628=y \
		CONFIG_SUPPORT_OPENWRT=y \
		modules
endef

define KernelPackage/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/lib/wifi/
	$(INSTALL_BIN) ./files/mt7628.sh $(1)/lib/wifi/
	$(INSTALL_DIR) $(1)/etc/wireless/$(PKG_NAME)/
	$(INSTALL_BIN) ./files/mt7628.dat $(1)/etc/wireless/$(PKG_NAME)/
	-if [ "$$(CONFIG_INTERNAL_PA_INTERNAL_LNA)" = "y" ]; then \
		$(INSTALL_BIN) ./files/mt7628.eeprom.ipa.ilna.bin $(1)/etc/wireless/$(PKG_NAME)/mt7628.eeprom.bin; \
	elif [ "$$(CONFIG_INTERNAL_PA_EXTERNAL_LNA)" = "y" ]; then \
		$(INSTALL_BIN) ./files/mt7628.eeprom.ipa.elna.bin $(1)/etc/wireless/$(PKG_NAME)/mt7628.eeprom.bin; \
	elif [ "$$(CONFIG_EXTERNAL_PA_EXTERNAL_LNA)" = "y" ]; then \
		$(INSTALL_BIN) ./files/mt7628.eeprom.epa.elna.bin $(1)/etc/wireless/$(PKG_NAME)/mt7628.eeprom.bin; \
	else \
		$(INSTALL_BIN) ./files/mt7628.eeprom.ipa.elna.bin $(1)/etc/wireless/$(PKG_NAME)/mt7628.eeprom.bin; \
	fi
	echo $(PKG_VERSION) > $(1)/etc/wireless/$(PKG_NAME)/version
endef

$(eval $(call KernelPackage,$(PKG_NAME)))
