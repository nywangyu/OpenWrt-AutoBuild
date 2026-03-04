
#!/bin/bash

# 软件源设置


# 指示灯定义
if ! grep -q "option name 'LAN'" /etc/config/system; then
    cat >> "/etc/config/system" << 'EOF'
config led
	option name 'LAN'
	option sysfs 'green:status'
	option trigger 'netdev'
	option dev 'br-lan'
	list mode 'tx'
	list mode 'rx'

config led
	option name 'Red Off'
	option sysfs 'red:status'
	option trigger 'none'
	option default '0'

config led
	option name 'Blue Off'
	option sysfs 'blue:status'
	option trigger 'timer'
	option delayon '100'
	option delayoff '1500'
EOF
fi

# ================ WIFI设置 =======================================

# 检查初始配置文件
if ! grep -q "option ssid 'ImmortalWrt'" /etc/config/wireless; then
    echo "检测到 /etc/config/wireless 文件不包含 ImmortalWrt 的 SSID，跳过配置"
    exit 0
fi

# 配置SSID信息
configure_wifi() {
    local radio=$1
    local channel=$2
    local htmode=$3
    local txpower=$4
    local ssid=$5
    local key=$6
    local encryption=$7

    # 无需设置 band，系统自动推断
    uci -q batch <<EOC
set wireless.radio${radio}.channel="${channel}"
set wireless.radio${radio}.htmode="${htmode}"
set wireless.radio${radio}.mu_beamformer='1'
set wireless.radio${radio}.country='CN'
set wireless.radio${radio}.txpower="${txpower}"
set wireless.radio${radio}.cell_density='0'
set wireless.radio${radio}.disabled='0'

set wireless.default_radio${radio}.ssid="${ssid}"
set wireless.default_radio${radio}.encryption="${encryption}"
set wireless.default_radio${radio}.key="${key}"
set wireless.default_radio${radio}.time_advertisement='2'
set wireless.default_radio${radio}.time_zone='CST-8'
set wireless.default_radio${radio}.wnm_sleep_mode='1'
set wireless.default_radio${radio}.wnm_sleep_mode_no_keys='1'
EOC

    # 特殊加密设置
    if [ "$encryption" = "sae-mixed" ]; then
        uci set wireless.default_radio${radio}.ocv='0'
        uci set wireless.default_radio${radio}.disassoc_low_ack='0'
    fi
}

# 配置无线接口
#            接口顺序    信道     HT频宽      功率      SSID               密码            加密方式
configure_wifi 0      6       'HE40'      25     'ImmortalWrt-2.4G'    '123456789'     'psk2+ccmp'
configure_wifi 1      44      'HE160'     25     'QWRT-5G'       '123456789'     'sae-mixed'

# 提交并重启
uci commit wireless
wifi

# =======================================================



