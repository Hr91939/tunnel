#!/bin/bash

# Color
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
  echo -e "\nPress Enter to return to main menu..."
  read -r _
}

function install_europe_client() {
  clear
  echo -e "${CYAN}🌍 Europe client installation started...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🌐 Enter server IP: " SERVER_IP

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

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
web_port = 2060
sniffer_log = "/root/backhaul.json"
log_level = "info"
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

  echo -e "${GREEN}✅ Client started, connecting to $SERVER_IP on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "\nPress Enter to return to main menu..."
  read -r _
}

function edit_server_config() {
  clear
  echo -e "${CYAN}📝 Editing Iran-Server configuration file:${RESET}"
  nano "$CONFIG_PATH"
  echo -e "\nPress Enter to return to Tunnel Config Menu..."
  read -r _
  edit_tunnel_menu
}

function edit_client_config() {
  clear
  echo -e "${CYAN}📝 Editing Europe-Client configuration file:${RESET}"
  nano "$CONFIG_PATH"
  echo -e "\nPress Enter to return to Tunnel Config Menu..."
  read -r _
  edit_tunnel_menu
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) 🇮🇷 Edit Iran-Server Config"
    echo -e "  2) 🇪🇺 Edit Europe-Client Config"
    echo -e "  3) 🔙 Back to Main Menu"
    echo -ne "\n   📝 Select option (1-3): "
    read -r SUB_CHOICE
    case "$SUB_CHOICE" in
      1) edit_server_config ;;
      2) edit_client_config ;;
      3) break ;;
      *) echo -e "${RED}❌ Invalid selection, try again.${RESET}"
         sleep 1 ;;
    esac
  done
}

function clean_backhaul_files() {
  clear
  read -rp "⚠️ Are you sure you want to remove all Backhaul files? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}❗ Operation cancelled.${RESET}"
    echo -e "\nPress Enter to return to main menu..."
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
  echo -e "\nPress Enter to return to main menu..."
  read -r _
}

function show_tunnel_status() {
  clear
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    echo -e "\nPress Enter to return to main menu..."
    read -r _
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | cut -d'"' -f2)
  local IP=$(grep -E '^remote_addr =|bind_addr =' "$CONFIG_PATH" | cut -d'"' -f2)
  local PORT=$(echo "$IP" | cut -d: -f2)
  local HOST=$(echo "$IP" | cut -d: -f1)

  echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
  echo -e "🌐 IP: ${YELLOW}$HOST${RESET}"
  echo -e "🔌 Port: ${YELLOW}$PORT${RESET}"

  echo -e "⏳ Pinging $HOST..."
  if ping -c 3 -W 1 "$HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Tunnel is reachable${RESET}"
  else
    echo -e "${RED}❌ Tunnel is not reachable${RESET}"
  fi

  echo -e "\nPress Enter to return to main menu..."
  read -r _
}

function view_logs() {
  clear
  echo -e "${CYAN}📜 Showing Backhaul service logs (Press Ctrl+C to exit)...${RESET}"
  journalctl -u backhaul.service -e -f
  echo -e "\nPress Enter to return to main menu..."
  read -r _
}

function service_status() {
  clear
  echo -e "${CYAN}⚙️ Backhaul Service Status:${RESET}"
  systemctl status backhaul.service --no-pager
  echo -e "\nPress Enter to return to main menu..."
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
    echo -e "  6) 📜 View Backhaul Logs"
    echo -e "  7) ⚙️ Show Backhaul Service Status"
    echo -e "  8) ❌ Exit"
    echo -ne "\n   📝 Select option (1-8): "
    read -r CHOICE

    case "$CHOICE" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) view_logs ;;
      7) service_status ;;
      8) clear
         echo -e "${GREEN}👋 Goodbye!${RESET}"
         exit 0 ;;
      *) echo -e "${RED}❌ Invalid selection, please try again.${RESET}"
         sleep 1 ;;
    esac
  done
}

# start
main_menu
