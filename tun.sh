#!/bin/bash

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
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}💚 Iran Server Installation${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  echo -e "${YELLOW}📦 Enter the ports one per line (e.g., 80). Press Enter to finish.${RESET}"
  PORTS=""
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    [[ "$PORT" =~ ^[0-9]+$ ]] || { echo -e "${RED}❌ Invalid port.${RESET}"; continue; }
    PORTS+="$PORT "
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS_ARRAY=$(echo "$PORTS" | sed 's/ /","/g')
  [ -n "$PORTS_ARRAY" ] && PORTS_ARRAY="\"$PORTS_ARRAY\""

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
ports = [ $PORTS_ARRAY ]
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
  systemctl start backhaul

  echo -e "${GREEN}✅ Server started on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
  read -r _
}

function install_europe_client() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}❤️ Europe Client Installation${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  read -rp "🌐 Enter server IP: " SERVER_IP
  read -rp "🔌 Enter server port: " SERVER_PORT
  read -rp "🔑 Enter token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}
  read -rp "📦 Enter ports one per line (e.g., 80). Press Enter to finish: " -a PORTS_ARRAY

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS=""
  for p in "${PORTS_ARRAY[@]}"; do
    if [[ "$p" =~ ^[0-9]+$ ]]; then
      PORTS+="$p, "
    fi
  done
  PORTS=${PORTS%, }

  cat > "$CONFIG_PATH" <<EOF
[client]
remote_addr = "$SERVER_IP:$SERVER_PORT"
token = "$TOKEN"
ports = [ $PORTS ]
EOF

  cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Backhaul Reverse Tunnel Client
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
  systemctl start backhaul

  echo -e "${GREEN}✅ Client connected to $SERVER_IP:$SERVER_PORT with token \"$TOKEN\".${RESET}"
  echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
  read -r _
}

function edit_server_config() {
  clear
  echo -e "${CYAN}Editing Iran-Server config...${RESET}"
  nano "$CONFIG_PATH"
  echo -e "${YELLOW}📥 Press Enter to return to edit tunnel menu...${RESET}"
  read -r _
  edit_tunnel_menu
}

function edit_client_config() {
  clear
  echo -e "${CYAN}Editing Europe-Client config...${RESET}"
  nano "$CONFIG_PATH"
  echo -e "${YELLOW}📥 Press Enter to return to edit tunnel menu...${RESET}"
  read -r _
  edit_tunnel_menu
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) Edit Iran-Server Config"
    echo -e "  2) Edit Europe-Client Config"
    echo -e "  3) Back to Main Menu"
    echo -ne "\n📝 Select option (1-3): "
    read -r SUB_CHOICE
    case "$SUB_CHOICE" in
      1) edit_server_config ;;
      2) edit_client_config ;;
      3) main_menu; break ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1 ;;
    esac
  done
}

function show_tunnel_status() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
    read -r _
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | cut -d'"' -f2)

  if grep -q '^\[server\]' "$CONFIG_PATH"; then
    echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
    echo -e "🌐 Server mode detected."
    echo -e "⏳ Pinging 8.8.8.8 to check internet connectivity..."
    PING_OUTPUT=$(ping -c 4 -W 1 8.8.8.8 2>/dev/null)
    if echo "$PING_OUTPUT" | grep -q "rtt"; then
      AVG_TIME=$(echo "$PING_OUTPUT" | grep "rtt" | awk -F'/' '{print $5}')
      echo -e "${GREEN}✅ Internet connectivity is OK. Average ping: ${AVG_TIME} ms${RESET}"
    else
      echo -e "${RED}❌ Cannot reach 8.8.8.8 (No internet connectivity).${RESET}"
    fi

  elif grep -q '^\[client\]' "$CONFIG_PATH"; then
    local REMOTE_ADDR=$(grep '^remote_addr = ' "$CONFIG_PATH" | cut -d'"' -f2)
    local HOST=$(echo "$REMOTE_ADDR" | cut -d: -f1)
    local PORT=$(echo "$REMOTE_ADDR" | cut -d: -f2)
    echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
    echo -e "🌐 Client mode detected."
    echo -e "🌐 Connecting to server: ${YELLOW}$HOST${RESET} on port ${YELLOW}$PORT${RESET}"
    echo -e "⏳ Pinging $HOST to check tunnel connectivity..."
    PING_OUTPUT=$(ping -c 4 -W 1 "$HOST" 2>/dev/null)
    if echo "$PING_OUTPUT" | grep -q "rtt"; then
      AVG_TIME=$(echo "$PING_OUTPUT" | grep "rtt" | awk -F'/' '{print $5}')
      echo -e "${GREEN}✅ Tunnel server is reachable. Average ping: ${AVG_TIME} ms${RESET}"
    else
      echo -e "${RED}❌ Tunnel server is NOT reachable.${RESET}"
    fi

  else
    echo -e "${RED}❌ Configuration file format not recognized.${RESET}"
  fi

  echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
  read -r _
}

function clean_backhaul_files() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🧹 Cleaning Backhaul Files...${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  systemctl stop backhaul
  rm -f /root/backhaul*
  rm -f "$CONFIG_PATH"
  systemctl disable backhaul
  rm -f "$SERVICE_PATH"
  systemctl daemon-reload

  echo -e "${GREEN}✅ All backhaul files removed and service stopped.${RESET}"
  echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
  read -r _
}

function show_logs() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📜 Backhaul Logs:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if ! systemctl is-active --quiet backhaul; then
    echo -e "${RED}❌ backhaul service is not running.${RESET}"
    echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
    read -r _
    return
  fi

  echo -e "${YELLOW}Press Ctrl+C to stop viewing logs and return to main menu.${RESET}"
  echo
  journalctl -u backhaul.service -f
  echo -e "${YELLOW}📥 Press Enter to return to main menu...${RESET}"
  read -r _
}

function main_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🌍 Please select an option:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) 💚 Install Iran-Server"
    echo -e "  2) ❤️ Install Europe-Client"
    echo -e "  3) ⚙️ Edit Tunnel Config"
    echo -e "  4) 🧹 Clean Backhaul Files"
    echo -e "  5) 📡 Tunnel Status"
    echo -e "  6) 📜 Show Logs"
    echo -e "  7) 🚪 Exit"
    echo -ne "\n   📝 Select option (1-7): "
    read -r CHOICE
    case "$CHOICE" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) show_logs ;;
      7) exit 0 ;;
      *) echo -e "${RED}❌ Invalid option. Try again.${RESET}" ; sleep 1 ;;
    esac
  done
}

main_menu
