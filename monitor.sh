#!/bin/bash
# 自动获取或手动指定端口
TUIC_PORT=${1:-10004}
INTERVAL=2
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

format_speed() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B/s"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB/s"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB/s"
    fi
}

# 获取 ZeroTier 网卡或默认网卡
IFACE=$(ip -o link show | awk -F': ' '/zt/ {print $2}' | head -n 1)
[ -z "$IFACE" ] && IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)

clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${BOLD}       TUIC v5 实时健康与流量监控 (A点)          ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo -e " 监控时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e " 监控网卡: ${YELLOW}$IFACE${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -en " [状态监测] TUIC 进程: "
pgrep -x "tuic" > /dev/null && echo -e "${GREEN}● 正在运行${NC}" || echo -e "${RED}○ 已停止${NC}"
echo -en " [端口监测] UDP/$TUIC_PORT: "
ss -unlp | grep -q ":$TUIC_PORT " && echo -e "${GREEN}● 正常监听${NC}" || echo -e "${RED}○ 未发现监听${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e " ${BOLD}流量实时统计 (Ctrl+C 退出):${NC}\n"

while true; do
    R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep $INTERVAL
    R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    RX_SPEED=$(( (R2 - R1) / INTERVAL ))
    TX_SPEED=$(( (T2 - T1) / INTERVAL ))
    echo -ne "\r 下载 (RX): ${GREEN}$(format_speed $RX_SPEED)${NC} | 上传 (TX): ${CYAN}$(format_speed $TX_SPEED)${NC}\033[K"
done
