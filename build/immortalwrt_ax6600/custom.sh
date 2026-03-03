
#!/bin/bash

# 安装额外依赖软件包
# sudo -E apt-get -y install rename

# 更新源
# ./scripts/feeds clean
./scripts/feeds update

# 添加第三方软件包
git clone https://github.com/kenzok8/small-package.git package/smpackage

# 删除部分默认包
rm -rf feeds/luci/applications/luci-app-qbittorrent
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-attendedsysupgrade
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf package/dbone-packages/passwall/packages/v2ray-geoview

# 安装源
./scripts/feeds install -a -f

#移除 luci-app-attendedsysupgrade 依赖
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 自定义定制选项
NET="package/base-files/files/bin/config_generate"
ZZZ="package/emortal/default-settings/files/99-default-settings"

#
sed -i "s#192.168.1.1#192.168.100.1#g" $NET                                                     # 定制默认IP
sed -i "s#ImmortalWrt#AX6000#g" $NET                                          # 修改默认名称为 AX6000
echo "uci set luci.main.mediaurlbase=/luci-static/argon" >> $ZZZ                      # 设置默认主题(如果编译可会自动修改默认主题的，有可能会失效)

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

BUILDTIME=$(TZ=UTC-8 date "+%Y.%m.%d") && sed -i "s/\(_('Firmware Version'), *\)/\1 ('ONE build $BUILDTIME @ ') + /" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js               # 增加自己个性名称
# wget -q https://raw.githubusercontent.com/VIKINGYFY/immortalwrt/refs/heads/main/package/firmware/ath11k-firmware/Makefile -O package/firmware/ath11k-firmware/Makefile --no-check-certificate               # 更新 ath11k-firmware Makefile


# ●●●●●●●●●●●●●●●●●●●●●●●●定制部分●●●●●●●●●●●●●●●●●●●●●●●● #

# ========================性能跑分========================

echo "rm -f /etc/uci-defaults/xxx-coremark" >> "$ZZZ"
cat >> $ZZZ <<EOF
cat /dev/null > /etc/bench.log
echo " (CpuMark : 23907.846120" >> /etc/bench.log
echo " Scores)" >> /etc/bench.log
EOF

# ================ 网络设置 =======================================

cat >> $ZZZ <<-EOF
# 设置网络-旁路由模式
uci set network.lan.gateway='192.168.100.3'                     # 旁路由设置 IPv4 网关
uci set network.lan.dns='223.5.5.5 119.29.29.29'            # 旁路由设置 DNS(多个DNS要用空格分开)
uci set dhcp.lan.ignore='1'                                  # 旁路由关闭DHCP功能
uci delete network.lan.type                                  # 旁路由桥接模式-禁用
uci set network.lan.delegate='0'                             # 去掉LAN口使用内置的 IPv6 管理(若用IPV6请把'0'改'1')
uci set dhcp.@dnsmasq[0].filter_aaaa='0'                     # 禁止解析 IPv6 DNS记录(若用IPV6请把'1'改'0')

# 设置防火墙-旁路由模式
uci set firewall.@defaults[0].synflood_protect='0'          # 禁用 SYN-flood 防御
uci set firewall.@defaults[0].flow_offloading='0'           # 禁用基于软件的NAT分载
uci set firewall.@defaults[0].flow_offloading_hw='0'       # 禁用基于硬件的NAT分载
uci set firewall.@defaults[0].fullcone='0'                   # 禁用 FullCone NAT
uci set firewall.@defaults[0].fullcone6='0'                  # 禁用 FullCone NAT6
uci set firewall.@zone[0].masq='1'                             # 启用LAN口 IP 动态伪装

# 旁路IPV6需要全部禁用
uci del network.lan.ip6assign                                 # IPV6分配长度-禁用
uci del dhcp.lan.ra                                             # 路由通告服务-禁用
uci del dhcp.lan.dhcpv6                                        # DHCPv6 服务-禁用
uci del dhcp.lan.ra_management                               # DHCPv6 模式-禁用

# 如果有用IPV6的话,可以使用以下命令创建IPV6客户端(LAN口)（去掉全部代码uci前面#号生效）
uci set network.ipv6=interface
uci set network.ipv6.proto='dhcpv6'
uci set network.ipv6.ifname='@lan'
uci set network.ipv6.reqaddress='try'
uci set network.ipv6.reqprefix='auto'
uci set firewall.@zone[0].network='lan ipv6'

# 配置Dropbear SSH服务
uci del dropbear.main.RootPasswordAuth
uci del dropbear.main.DirectInterface
uci set dropbear.main.enable='1'
uci set dropbear.main.Interface='lan'

uci commit dhcp
uci commit network
uci commit firewall
uci commit dropbear
/etc/init.d/dropbear restart

EOF

# 修改退出命令到最后
cd $HOME && sed -i '/exit 0/d' $ZZZ && echo "exit 0" >> $ZZZ

# ================ 网络设置 =======================================


# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #


# 创建自定义配置文件

cd $WORKPATH
touch ./.config

#
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分●●●●●●●●●●●●●●●●●●●●●●●●
# 

# 
# 如果不对本区块做出任何编辑, 则生成默认配置固件. 
# 

# 以下为定制化固件选项和说明:
#

#
# 有些插件/选项是默认开启的, 如果想要关闭, 请参照以下示例进行编写:
# 
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#        ■|  # 取消编译VMware镜像:                    |■
#        ■|  cat >> .config <<EOF                   |■
#        ■|  # CONFIG_VMDK_IMAGES is not set        |■
#        ■|  EOF                                    |■
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#

# 
# 以下是一些提前准备好的一些插件选项.
# 直接取消注释相应代码块即可应用. 不要取消注释代码块上的汉字说明.
# 如果不需要代码块里的某一项配置, 只需要删除相应行.
#
# 如果需要其他插件, 请按照示例自行添加.
# 注意, 只需添加依赖链顶端的包. 如果你需要插件 A, 同时 A 依赖 B, 即只需要添加 A.
# 
# 无论你想要对固件进行怎样的定制, 都需要且只需要修改 EOF 回环内的内容.
# 

# 编译 百里 AX6000 固件:
cat >> .config <<EOF
# TARGET config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_jdcloud_re-cp-03=y

## 使用mtwifi-cfg无线配置
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y
CONFIG_PACKAGE_luci-i18n-mtwifi-cfg-zh-cn=y
CONFIG_PACKAGE_mtwifi-cfg=y
CONFIG_PACKAGE_lua-cjson=y
## 使用新的无线firmware
CONFIG_MTK_MT7986_NEW_FW=y
CONFIG_WARP_NEW_FW=y
CONFIG_DEVEL=y
CONFIG_TOOLCHAINOPTS=y
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_AFALG_UPDATE_CTR_IV=y
CONFIG_ARIA2_BITTORRENT=y
CONFIG_ARIA2_NOXML=y
CONFIG_ARIA2_OPENSSL=y
CONFIG_ARIA2_WEBSOCKET=y
CONFIG_BUSYBOX_CONFIG_BLKID=y
CONFIG_BUSYBOX_CONFIG_DIFF=y
CONFIG_BUSYBOX_CONFIG_FEATURE_BLKID_TYPE=y
CONFIG_BUSYBOX_CONFIG_VOLUMEID=y
CONFIG_CONNINFRA_AUTO_UP=y
CONFIG_CONNINFRA_EMI_SUPPORT=y
# CONFIG_GDB is not set
CONFIG_GNUTLS_ALPN=y
CONFIG_GNUTLS_ANON=y
CONFIG_GNUTLS_CRYPTODEV=y
CONFIG_GNUTLS_DTLS_SRTP=y
CONFIG_GNUTLS_HEARTBEAT=y
CONFIG_GNUTLS_OCSP=y
CONFIG_GNUTLS_PSK=y
CONFIG_INCLUDE_CONFIG=y
CONFIG_JSON_OVERVIEW_IMAGE_INFO=y
# CONFIG_KERNEL_BLK_DEV_THROTTLING is not set
# CONFIG_KERNEL_CFS_BANDWIDTH is not set
CONFIG_KERNEL_DEVMEM=y
# CONFIG_KERNEL_KEYS is not set
# CONFIG_KERNEL_MEMCG_SWAP is not set
CONFIG_MTK_ACK_CTS_TIMEOUT_SUPPORT=y
CONFIG_MTK_AIR_MONITOR=y
CONFIG_MTK_AMPDU_CONF_SUPPORT=y
CONFIG_MTK_ANTENNA_CONTROL_SUPPORT=y
CONFIG_MTK_APCLI_SUPPORT=y
CONFIG_MTK_ATE_SUPPORT=y
CONFIG_MTK_BACKGROUND_SCAN_SUPPORT=y
CONFIG_MTK_CAL_BIN_FILE_SUPPORT=y
CONFIG_MTK_CFG_SUPPORT_FALCON_MURU=y
CONFIG_MTK_CFG_SUPPORT_FALCON_PP=y
CONFIG_MTK_CFG_SUPPORT_FALCON_SR=y
CONFIG_MTK_CFG_SUPPORT_FALCON_TXCMD_DBG=y
CONFIG_MTK_CHIP_MT7986=y
CONFIG_MTK_CONNINFRA_APSOC=y
CONFIG_MTK_CONNINFRA_APSOC_MT7986=y
CONFIG_MTK_CON_WPS_SUPPORT=y
CONFIG_MTK_DBDC_MODE=y
CONFIG_MTK_DOT11K_RRM_SUPPORT=y
CONFIG_MTK_DOT11R_FT_SUPPORT=y
CONFIG_MTK_DOT11W_PMF_SUPPORT=y
CONFIG_MTK_DOT11_HE_AX=y
CONFIG_MTK_DOT11_N_SUPPORT=y
CONFIG_MTK_DOT11_VHT_AC=y
CONFIG_MTK_FAST_NAT_SUPPORT=y
CONFIG_MTK_FIRST_IF_EEPROM_FLASH=y
CONFIG_MTK_FIRST_IF_IPAILNA=y
CONFIG_MTK_FIRST_IF_MT7986=y
CONFIG_MTK_GREENAP_SUPPORT=y
CONFIG_MTK_G_BAND_256QAM_SUPPORT=y
CONFIG_MTK_HDR_TRANS_RX_SUPPORT=y
CONFIG_MTK_HDR_TRANS_TX_SUPPORT=y
CONFIG_MTK_ICAP_SUPPORT=y
CONFIG_MTK_IGMP_SNOOP_SUPPORT=y
CONFIG_MTK_INTERWORKING=y
CONFIG_MTK_MAP_R2_VER_SUPPORT=y
CONFIG_MTK_MAP_R3_VER_SUPPORT=y
CONFIG_MTK_MAP_SUPPORT=y
CONFIG_MTK_MBSS_DTIM_SUPPORT=y
CONFIG_MTK_MBSS_SUPPORT=y
CONFIG_MTK_MCAST_RATE_SPECIFIC=y
CONFIG_MTK_MGMT_TXPWR_CTRL=y
CONFIG_MTK_MLME_MULTI_QUEUE_SUPPORT=y
CONFIG_MTK_MT7986_NEW_FW=y
CONFIG_MTK_MT_AP_SUPPORT=m
CONFIG_MTK_MT_DFS_SUPPORT=y
CONFIG_MTK_MT_MAC=y
CONFIG_MTK_MT_WIFI=m
CONFIG_MTK_MT_WIFI_PATH="mt_wifi"
CONFIG_MTK_MUMIMO_SUPPORT=y
CONFIG_MTK_MU_RA_SUPPORT=y
CONFIG_MTK_OFFCHANNEL_SCAN_FEATURE=y
CONFIG_MTK_OWE_SUPPORT=y
CONFIG_MTK_PHY_ICS_SUPPORT=y
CONFIG_MTK_QOS_R1_SUPPORT=y
CONFIG_MTK_RA_PHY_RATE_SUPPORT=y
CONFIG_MTK_RED_SUPPORT=y
CONFIG_MTK_RTMP_FLASH_SUPPORT=y
CONFIG_MTK_RT_FIRST_CARD_EEPROM="flash"
CONFIG_MTK_RT_FIRST_IF_RF_OFFSET=0xc0000
CONFIG_MTK_SCS_FW_OFFLOAD=y
CONFIG_MTK_SECOND_IF_NONE=y
CONFIG_MTK_SMART_CARRIER_SENSE_SUPPORT=y
CONFIG_MTK_SPECTRUM_SUPPORT=y
CONFIG_MTK_SUPPORT_OPENWRT=y
CONFIG_MTK_THERMAL_PROTECT_SUPPORT=y
CONFIG_MTK_THIRD_IF_NONE=y
CONFIG_MTK_TPC_SUPPORT=y
CONFIG_MTK_TXBF_SUPPORT=y
CONFIG_MTK_UAPSD=y
CONFIG_MTK_VLAN_SUPPORT=y
CONFIG_MTK_VOW_SUPPORT=y
CONFIG_MTK_WARP_V2=y
CONFIG_MTK_WDS_SUPPORT=y
CONFIG_MTK_WHNAT_SUPPORT=m
CONFIG_MTK_WIFI_ADIE_TYPE="mt7976"
CONFIG_MTK_WIFI_BASIC_FUNC=y
CONFIG_MTK_WIFI_DRIVER=y
CONFIG_MTK_WIFI_EAP_FEATURE=y
CONFIG_MTK_WIFI_FW_BIN_LOAD=y
CONFIG_MTK_WIFI_MODE_AP=m
CONFIG_MTK_WIFI_MT_MAC=y
CONFIG_MTK_WIFI_SKU_TYPE="AX6000"
CONFIG_MTK_WIFI_TWT_SUPPORT=y
CONFIG_MTK_WLAN_HOOK=y
CONFIG_MTK_WLAN_SERVICE=y
CONFIG_MTK_WNM_SUPPORT=y
CONFIG_MTK_WPA3_SUPPORT=y
CONFIG_MTK_WSC_INCLUDED=y
CONFIG_MTK_WSC_V2_SUPPORT=y
# CONFIG_OPENSSL_ENGINE_BUILTIN is not set
# CONFIG_OPENSSL_PREFER_CHACHA_OVER_GCM is not set
CONFIG_OPENSSL_WITH_NPN=y
CONFIG_PACKAGE_TAR_BZIP2=y
CONFIG_PACKAGE_TAR_GZIP=y
CONFIG_PACKAGE_TAR_XZ=y
CONFIG_PACKAGE_TAR_ZSTD=y
# CONFIG_PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING is not set
CONFIG_PACKAGE_TURBOACC_INCLUDE_NO_FASTPATH=y
CONFIG_PACKAGE_adbyby=y
CONFIG_PACKAGE_alist=y
CONFIG_PACKAGE_aria2=y
CONFIG_PACKAGE_ariang=y
CONFIG_PACKAGE_attr=y
CONFIG_PACKAGE_autosamba=y
CONFIG_PACKAGE_avahi-dbus-daemon=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_blockd=y
CONFIG_PACKAGE_bzip2=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_coreutils-stat=y
CONFIG_PACKAGE_coreutils-stty=y
CONFIG_PACKAGE_datconf=y
CONFIG_PACKAGE_datconf-lua=y
CONFIG_PACKAGE_dbus=y
CONFIG_PACKAGE_ddnsto=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_ebtables=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_fuse-utils=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_ip-bridge=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_ip6tables-extra=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
CONFIG_PACKAGE_iptables-mod-filter=y
CONFIG_PACKAGE_iptables-mod-hashlimit=y
CONFIG_PACKAGE_iptables-mod-iface=y
CONFIG_PACKAGE_iptables-mod-ipmark=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_iptables-mod-iprange=y
CONFIG_PACKAGE_iptables-mod-ipv4options=y
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_iptables-mod-proto=y
CONFIG_PACKAGE_iptables-mod-tee=y
CONFIG_PACKAGE_iptables-mod-u32=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_kmod-ata-core=y
CONFIG_PACKAGE_kmod-conninfra=y
CONFIG_PACKAGE_kmod-crypto-acompress=y
CONFIG_PACKAGE_kmod-crypto-ccm=y
CONFIG_PACKAGE_kmod-crypto-cmac=y
CONFIG_PACKAGE_kmod-crypto-crc32c=y
CONFIG_PACKAGE_kmod-crypto-ctr=y
CONFIG_PACKAGE_kmod-crypto-des=y
CONFIG_PACKAGE_kmod-crypto-gcm=y
CONFIG_PACKAGE_kmod-crypto-gf128=y
CONFIG_PACKAGE_kmod-crypto-ghash=y
CONFIG_PACKAGE_kmod-crypto-hmac=y
CONFIG_PACKAGE_kmod-crypto-md4=y
CONFIG_PACKAGE_kmod-crypto-md5=y
CONFIG_PACKAGE_kmod-crypto-seqiv=y
CONFIG_PACKAGE_kmod-crypto-sha512=y
CONFIG_PACKAGE_kmod-ebtables=y
CONFIG_PACKAGE_kmod-ebtables-ipv4=y
CONFIG_PACKAGE_kmod-ebtables-ipv6=y
CONFIG_PACKAGE_kmod-fs-autofs4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fuse=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-ip6tables-extra=y
CONFIG_PACKAGE_kmod-ipt-compat-xtables=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-filter=y
CONFIG_PACKAGE_kmod-ipt-hashlimit=y
CONFIG_PACKAGE_kmod-ipt-iface=y
CONFIG_PACKAGE_kmod-ipt-ipmark=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_kmod-ipt-iprange=y
CONFIG_PACKAGE_kmod-ipt-ipv4options=y
CONFIG_PACKAGE_kmod-ipt-nat-extra=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-ipt-proto=y
CONFIG_PACKAGE_kmod-ipt-raw6=y
CONFIG_PACKAGE_kmod-ipt-tee=y
CONFIG_PACKAGE_kmod-ipt-u32=y
CONFIG_PACKAGE_kmod-leds-ws2812b=y
CONFIG_PACKAGE_kmod-lib-crc32c=y
CONFIG_PACKAGE_kmod-lib-lzo=y
CONFIG_PACKAGE_kmod-lib-zlib-deflate=y
CONFIG_PACKAGE_kmod-lib-zlib-inflate=y
CONFIG_PACKAGE_kmod-md-mod=y
CONFIG_PACKAGE_kmod-md-raid0=y
CONFIG_PACKAGE_kmod-md-raid1=y
CONFIG_PACKAGE_kmod-md-raid10=y
CONFIG_PACKAGE_kmod-mediatek_hnat=y
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-nls-utf8=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-scsi-core=y
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-warp=y
CONFIG_PACKAGE_kmod-zram=y
CONFIG_PACKAGE_koolproxy=y
CONFIG_PACKAGE_kvcedit=y
CONFIG_PACKAGE_libatomic=y
CONFIG_PACKAGE_libattr=y
CONFIG_PACKAGE_libavahi-client=y
CONFIG_PACKAGE_libavahi-dbus-support=y
CONFIG_PACKAGE_libbpf=y
CONFIG_PACKAGE_libbz2=y
CONFIG_PACKAGE_libcap-bin=y
CONFIG_PACKAGE_libcap-bin-capsh-shell="/bin/sh"
CONFIG_PACKAGE_libcap-ng=y
CONFIG_PACKAGE_libcbor=y
CONFIG_PACKAGE_libcomerr=y
CONFIG_PACKAGE_libdaemon=y
CONFIG_PACKAGE_libdb47=y
CONFIG_PACKAGE_libdbus=y
CONFIG_PACKAGE_libelf=y
CONFIG_PACKAGE_libevdev=y
CONFIG_PACKAGE_libexpat=y
CONFIG_PACKAGE_libext2fs=y
CONFIG_PACKAGE_libfido2=y
CONFIG_PACKAGE_libfuse=y
CONFIG_PACKAGE_libgnutls=y
CONFIG_PACKAGE_libipset=y
CONFIG_PACKAGE_libkvcutil=y
CONFIG_PACKAGE_liblzma=y
CONFIG_PACKAGE_libminiupnpc=y
CONFIG_PACKAGE_libmount=y
CONFIG_PACKAGE_libnatpmp=y
CONFIG_PACKAGE_libnl=y
CONFIG_PACKAGE_libnl-core=y
CONFIG_PACKAGE_libnl-genl=y
CONFIG_PACKAGE_libnl-nf=y
CONFIG_PACKAGE_libnl-route=y
CONFIG_PACKAGE_libopenssl-afalg_sync=y
CONFIG_PACKAGE_libopenssl-devcrypto=y
CONFIG_PACKAGE_libpcap=y
CONFIG_PACKAGE_libpopt=y
CONFIG_PACKAGE_libreadline=y
CONFIG_PACKAGE_libruby=y
CONFIG_PACKAGE_libss=y
CONFIG_PACKAGE_libstdcpp=y
CONFIG_PACKAGE_libtasn1=y
CONFIG_PACKAGE_libtirpc=y
CONFIG_PACKAGE_libuci-lua=y
CONFIG_PACKAGE_libudev-zero=y
CONFIG_PACKAGE_liburing=y
CONFIG_PACKAGE_libyaml=y
CONFIG_PACKAGE_libzstd=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_lua-cjson=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-app-ddnsto=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-i18n-dufs-zh-cn=y
CONFIG_PACKAGE_luci-i18n-nikki-zh-cn=y
CONFIG_PACKAGE_luci-i18n-mosdns-zh-cn=y
CONFIG_PACKAGE_luci-i18n-easytier-zh-cn=y
CONFIG_PACKAGE_luci-app-eqos-mtk=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-quickstart=y
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-ng is not set
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-webui is not set
CONFIG_PACKAGE_luci-app-samba4=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ChinaDNS_NG is not set
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_NONE_V2RAY=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client is not set
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Server=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Simple_Obfs is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray is not set
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-app-turboacc-mtk=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
CONFIG_PACKAGE_luci-i18n-eqos-mtk-zh-cn=y
CONFIG_PACKAGE_luci-i18n-lucky-zh-cn=y
CONFIG_PACKAGE_luci-i18n-mtwifi-cfg-zh-cn=y
CONFIG_PACKAGE_luci-i18n-quickstart-zh-cn=y
CONFIG_PACKAGE_luci-i18n-samba4-zh-cn=y
CONFIG_PACKAGE_luci-i18n-turboacc-mtk-zh-cn=y
CONFIG_PACKAGE_luci-i18n-upnp-zh-cn=y
CONFIG_PACKAGE_luci-lib-taskd=y
CONFIG_PACKAGE_luci-lib-xterm=y
CONFIG_PACKAGE_luci-theme-bootstrap-mod=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_lucky=y
CONFIG_PACKAGE_mdadm=y
CONFIG_PACKAGE_mii_mgr=y
CONFIG_PACKAGE_miniupnpd=y
CONFIG_PACKAGE_mtkhqos_util=y
CONFIG_PACKAGE_mtwifi-cfg=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_openssh-keygen=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_openssl-util=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_quickstart=y
CONFIG_PACKAGE_regs=y
CONFIG_PACKAGE_resolveip=y
CONFIG_PACKAGE_ruby=y
CONFIG_PACKAGE_ruby-bigdecimal=y
CONFIG_PACKAGE_ruby-date=y
CONFIG_PACKAGE_ruby-dbm=y
CONFIG_PACKAGE_ruby-digest=y
CONFIG_PACKAGE_ruby-enc=y
CONFIG_PACKAGE_ruby-forwardable=y
CONFIG_PACKAGE_ruby-pstore=y
CONFIG_PACKAGE_ruby-psych=y
CONFIG_PACKAGE_ruby-stringio=y
CONFIG_PACKAGE_ruby-strscan=y
CONFIG_PACKAGE_ruby-yaml=y
CONFIG_PACKAGE_script-utils=y
CONFIG_PACKAGE_shadow=y
CONFIG_PACKAGE_shadow-chage=y
CONFIG_PACKAGE_shadow-chfn=y
CONFIG_PACKAGE_shadow-chgpasswd=y
CONFIG_PACKAGE_shadow-chpasswd=y
CONFIG_PACKAGE_shadow-chsh=y
CONFIG_PACKAGE_shadow-common=y
CONFIG_PACKAGE_shadow-expiry=y
CONFIG_PACKAGE_shadow-faillog=y
CONFIG_PACKAGE_shadow-gpasswd=y
CONFIG_PACKAGE_shadow-groupadd=y
CONFIG_PACKAGE_shadow-groupdel=y
CONFIG_PACKAGE_shadow-groupmems=y
CONFIG_PACKAGE_shadow-groupmod=y
CONFIG_PACKAGE_shadow-groups=y
CONFIG_PACKAGE_shadow-grpck=y
CONFIG_PACKAGE_shadow-grpconv=y
CONFIG_PACKAGE_shadow-grpunconv=y
CONFIG_PACKAGE_shadow-lastlog=y
CONFIG_PACKAGE_shadow-login=y
CONFIG_PACKAGE_shadow-logoutd=y
CONFIG_PACKAGE_shadow-newgidmap=y
CONFIG_PACKAGE_shadow-newgrp=y
CONFIG_PACKAGE_shadow-newuidmap=y
CONFIG_PACKAGE_shadow-newusers=y
CONFIG_PACKAGE_shadow-nologin=y
CONFIG_PACKAGE_shadow-passwd=y
CONFIG_PACKAGE_shadow-pwck=y
CONFIG_PACKAGE_shadow-pwconv=y
CONFIG_PACKAGE_shadow-pwunconv=y
CONFIG_PACKAGE_shadow-su=y
CONFIG_PACKAGE_shadow-useradd=y
CONFIG_PACKAGE_shadow-userdel=y
CONFIG_PACKAGE_shadow-usermod=y
CONFIG_PACKAGE_shadow-utils=y
CONFIG_PACKAGE_shadow-vipw=y
CONFIG_PACKAGE_smartd=y
CONFIG_PACKAGE_smartmontools=y
CONFIG_PACKAGE_swconfig=y
CONFIG_PACKAGE_switch=y
CONFIG_PACKAGE_tar=y
CONFIG_PACKAGE_taskd=y
CONFIG_PACKAGE_tc-mod-iptables=y
CONFIG_PACKAGE_tc-tiny=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_wifi-dats=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_wireless-tools=y
CONFIG_PACKAGE_wsdd2=y
CONFIG_PACKAGE_xz=y
CONFIG_PACKAGE_xz-utils=y
CONFIG_PACKAGE_zerotier=y
CONFIG_PACKAGE_zram-swap=y
CONFIG_PARTED_READLINE=y
# CONFIG_PKG_CHECK_FORMAT_SECURITY is not set
# CONFIG_PKG_FORTIFY_SOURCE_1 is not set
CONFIG_PKG_FORTIFY_SOURCE_2=y
CONFIG_SAMBA4_SERVER_AVAHI=y
CONFIG_SAMBA4_SERVER_NETBIOS=y
CONFIG_SAMBA4_SERVER_VFS=y
CONFIG_SAMBA4_SERVER_WSDD2=y
CONFIG_WARP_CHIPSET="mt7986"
CONFIG_WARP_DBG_SUPPORT=y
CONFIG_WARP_MEMORY_LEAK_DBG=y
CONFIG_WARP_NEW_FW=y
CONFIG_WARP_VERSION=2
CONFIG_WED_HW_RRO_SUPPORT=y
# CONFIG_WOLFSSL_HAS_ECC25519 is not set
CONFIG_ZSTD_OPTIMIZE_O3=y
CONFIG_first_card=y
CONFIG_first_card_name="MT7986"
CONFIG_shadow-all=y
# CONFIG_AFALG_FALLBACK is not set
# CONFIG_MTK_BAND_STEERING is not set
# CONFIG_MTK_DEFAULT_5G_PROFILE is not set
# CONFIG_MTK_MAC_REPEATER_SUPPORT is not set
# CONFIG_MTK_MULTI_PROFILE_SUPPORT is not set
# CONFIG_MTK_PCIE_ASPM_DYM_CTRL_SUPPORT is not set
# CONFIG_MTK_PRE_CAL_TRX_SET1_SUPPORT is not set
# CONFIG_MTK_PRE_CAL_TRX_SET2_SUPPORT is not set
# CONFIG_MTK_RLM_CAL_CACHE_SUPPORT is not set
# CONFIG_MTK_SNIFFER_RADIOTAP_SUPPORT is not set
EOF


# 
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分结束●●●●●●●●●●●●●●●●●●●●●●●● #
# 

sed -i 's/^[ \t]*//g' ./.config

# 返回目录
cd $HOME

# 配置文件创建完成
