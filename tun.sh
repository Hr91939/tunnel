#!/bin/bash

# Colors
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
  echo -e "${CYAN}🌍 Iran server installation started...${RESET}"

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
  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function install_europe_client() {
  clear
  echo -e "${CYAN}🌍 Europe client installation started...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🌐 Enter the server IP: " SERVER_IP
  while [[ ! $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo -e "${RED}❌ Invalid IP address.${RESET}"
    read -rp "🌐 Enter the server IP: " SERVER_IP
  done

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  cat > "$CONFIG_PATH" <<EOF
[client]
remote_addr = "$SERVER_IP:$TUNNEL_PORT"
transport = "tcp"
accept_udp = false
token = "$TOKEN"
keepalive_period = 75
nodelay = true
heartbeat = 40
channel_size = 2048
sniffer = false
log_level = "info"
EOF

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  echo -e "${GREEN}✅ Client configured to connect to $SERVER_IP on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function edit_server_config() {
  clear
  echo -e "${CYAN}✏️ Edit Iran Server Config:${RESET}"
  nano "$CONFIG_PATH"
}

function edit_client_config() {
  clear
  echo -e "${CYAN}✏️ Edit Europe Client Config:${RESET}"
  nano "$CONFIG_PATH"
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
    echo -e "  1) Edit Iran-Server Config"
    echo -e "  2) Edit Europe-Client Config"
    echo -e "  3) Back to Main Menu"
    echo -ne "\n📝 Select option (1-3): "
    read -r SUB_CHOICE
    case "$SUB_CHOICE" in
      1) edit_server_config ;;
      2) edit_client_config ;;
      3) break ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1 ;;
    esac
  done
}

function show_tunnel_status() {
  clear
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    echo -ne "\n📥 Press Enter to return to main menu..."
    read -r _
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | cut -d'"' -f2)
  local REMOTE_LINE=$(grep -E '^remote_addr =|bind_addr =' "$CONFIG_PATH")
  local IP_PORT=$(echo "$REMOTE_LINE" | cut -d'"' -f2)
  local PORT=$(echo "$IP_PORT" | cut -d: -f2)
  local HOST=$(echo "$IP_PORT" | cut -d: -f1)

  # Decide ping target
  local PING_TARGET=""
  if grep -q "\[server\]" "$CONFIG_PATH"; then
    # Iran server: ping 8.8.8.8
    PING_TARGET="8.8.8.8"
  else
    # Client: ping the server IP from config
    PING_TARGET="$HOST"
  fi

  echo -e "Connecting to server: ${GREEN}$HOST${RESET} on port ${GREEN}$PORT${RESET}"
  echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
  echo -e "⏳ Pinging $PING_TARGET to check tunnel connectivity..."

  # Ping and calculate average of first 4 pings
  local PING_RESULT
  PING_RESULT=$(ping -c 4 -W 1 "$PING_TARGET" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
  if [ -n "$PING_RESULT" ]; then
    echo -e "${GREEN}✅ Tunnel server is reachable. Average ping: ${PING_RESULT} ms${RESET}"
  else
    echo -e "${RED}❌ Tunnel server is not reachable.${RESET}"
  fi

  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function clean_backhaul_files() {
  read -rp "⚠️ Are you sure you want to remove all Backhaul files? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}❗ Operation cancelled.${RESET}"
    echo -ne "\n📥 Press Enter to return to main menu..."
    read -r _
    return
  fi

  echo -e "${YELLOW}🧹 Cleaning Backhaul files...${RESET}"
  rm -f "$BACKHAUL_DIR"/backhaul_linux_amd64.tar.gz
  rm -f "$BACKHAUL_DIR"/backhaul.json
  rm -f "$BACKHAUL_DIR"/config.toml
  rm -f /root/LICENSE
  rm -f /root/README.md
  echo -e "${GREEN}✅ Files cleaned.${RESET}"
  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function restart_backhaul_service() {
  echo -e "${CYAN}🔄 Restarting Backhaul service...${RESET}"
  systemctl restart backhaul
  sleep 1
  systemctl status backhaul --no-pager -n 3
  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function show_logs() {
  echo -e "${CYAN}📜 Showing Backhaul logs. Press Ctrl+C to exit.${RESET}"
  journalctl -u backhaul.service -f
  echo -ne "\n📥 Press Enter to return to main menu..."
  read -r _
}

function show_help() {
  clear
  echo -e "${MAGENTA}📚 Backhaul Tunnel Guide${RESET}"
  echo -e "${CYAN}🔐 The token of both servers must be the same.${RESET}"
  echo -e "${CYAN}🔌 The tunnel port of both servers must be the same.${RESET}"
  echo -e "${YELLOW}⚠️ Before creating a new tunnel, select option 4 (Clean Backhaul Files) to delete existing files if you already have a tunnel.${RESET}"
  echo -e "\n${GREEN}🚀 Follow these to avoid connectivity issues!${RESET}"
  echo -ne "\n📥 Press Enter to return to main menu..."
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
    echo -e "  6) 🔄 Restart Backhaul Service"
    echo -e "  7) 📜 Show Backhaul Logs"
    echo -e "  8) 📖 Help & Guide"
    echo -e "  9) 🚪 Exit"
    echo -ne "\n   📝 Select option (1-9): "
    read -r CHOICE

    case "$CHOICE" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) restart_backhaul_service ;;
      7) show_logs ;;
      8) show_help ;;
      9) clear; echo -e "${CYAN}👋 Goodbye!${RESET}"; exit 0 ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1 ;;
    esac
  done
}

main_menu
