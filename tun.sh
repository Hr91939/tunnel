#!/bin/bash

# رنگ‌ها برای خروجی زیباتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

CONFIG_PATH="/root/config.toml"
SERVICE_PATH="/etc/systemd/system/backhaul.service"
BACKHAUL_DIR="/root"

function install_iran_server() {
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}💚 Installing Server (Iran Side)...${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  echo -e "${YELLOW}📦 Enter the ports one per line. Press Enter without input to finish.${RESET}"
  PORTS_LIST=()
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
      echo -e "${RED}❌ Invalid port. Please enter only numbers.${RESET}"
      continue
    fi
    if [[ " ${PORTS_LIST[*]} " =~ " $PORT " ]]; then
      echo -e "${RED}⚠️ Port $PORT already added.${RESET}"
      continue
    fi
    PORTS_LIST+=("$PORT")
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt -qq update > /dev/null
  apt -qq install -y wget tar > /dev/null

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS_ARRAY=""
  for p in "${PORTS_LIST[@]}"; do
    PORTS_ARRAY+="\"$p\",\n"
  done

  cat > "$CONFIG_PATH" <<EOF
[server]
bind_addr = "0.0.0.0:$TUNNEL_PORT"
transport = "tcp"
accept_udp = false
token = "$TOKEN"
keepalive_period = 75
nodelay = true
heartbeat = 40
channel_size = 2048
sniffer = false
web_port = 2060
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = [
$PORTS_ARRAY]
EOF

  cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Backhaul Reverse Tunnel Server
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul -c /root/config.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable backhaul
  systemctl restart backhaul

  echo -e "${GREEN}✅ Server installation complete.${RESET}"
}

# تابع راه‌اندازی منوی اصلی برای تست تابع بالا
function main_menu() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🌍 Please select an option:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  1) 💚 Install Iran-Server"
  echo -e "  2) ❌ Exit"
  echo -ne "\n   📝 Select option (1-2): "
  read -r CHOICE
  case "$CHOICE" in
    1) install_iran_server ;;
    2) exit 0 ;;
    *) echo -e "${RED}❌ Invalid selection.${RESET}" ;;
  esac
}

main_menu
