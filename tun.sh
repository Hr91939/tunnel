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
  echo -e "${CYAN}💚 Installing Iran-Server...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  echo -e "${YELLOW}📦 Enter ports one per line (e.g., 80). Press Enter without input to finish.${RESET}"
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

  echo -e "${GREEN}✅ Iran Server started on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function install_europe_client() {
  clear
  echo -e "${CYAN}❤️ Installing Europe-Client...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🌐 Enter the server IP: " SERVER_IP
  while [[ -z "$SERVER_IP" ]]; do
    echo -e "${RED}❌ IP cannot be empty.${RESET}"
    read -rp "🌐 Enter the server IP: " SERVER_IP
  done

  read -rp "🔌 Enter the server port (default: 64320): " SERVER_PORT
  SERVER_PORT=${SERVER_PORT:-64320}

  cat > "$CONFIG_PATH" <<EOF
[client]
remote_addr = "$SERVER_IP:$SERVER_PORT"
token = "$TOKEN"
keepalive_period = 75
heartbeat = 40
sniffer = false
log_level = "info"
EOF

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

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

  echo -e "${GREEN}✅ Europe Client started connecting to $SERVER_IP:$SERVER_PORT with token \"$TOKEN\".${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function edit_server_config() {
  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Configuration file not found.${RESET}"
    read -rp "📥 Press Enter to return..."
    return
  fi
  nano "$CONFIG_PATH"
}

function edit_client_config() {
  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Configuration file not found.${RESET}"
    read -rp "📥 Press Enter to return..."
    return
  fi
  nano "$CONFIG_PATH"
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
    echo -e "  1) Edit 💚Iran-Server Config"
    echo -e "  2) Edit ❤️Europe-Client Config"
    echo -e "  3) Back to Main Menu"
    read -rp "📝 Select option (1-3): " SUB_CHOICE
    case "$SUB_CHOICE" in
      1) edit_server_config ;;
      2) edit_client_config ;;
      3) break ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}" ;;
    esac
  done
}

function clean_backhaul_files() {
  read -rp "⚠️ Are you sure you want to remove all Backhaul files? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}❗ Operation cancelled.${RESET}"
    read -rp "📥 Press Enter to return to main menu..."
    return
  fi

  echo -e "${YELLOW}🧹 Cleaning Backhaul files...${RESET}"
  rm -f "$BACKHAUL_DIR"/backhaul_linux_amd64.tar.gz
  rm -f "$BACKHAUL_DIR"/backhaul.json
  rm -f "$BACKHAUL_DIR"/config.toml
  rm -f /root/LICENSE
  rm -f /root/README.md
  systemctl stop backhaul 2>/dev/null
  systemctl disable backhaul 2>/dev/null
  rm -f "$SERVICE_PATH"
  systemctl daemon-reload
  echo -e "${GREEN}✅ Files cleaned and service removed.${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function get_average_ping() {
  local host=$1
  local ping_output
  ping_output=$(ping -c 4 -W 1 "$host" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
  if [ -z "$ping_output" ]; then
    echo "N/A"
    return
  fi
  local sum=0
  local count=0
  for time in $ping_output; do
    sum=$(echo "$sum + $time" | bc)
    count=$((count + 1))
  done
  if [ "$count" -eq 0 ]; then
    echo "N/A"
  else
    echo "scale=3; $sum / $count" | bc
  fi
}

function show_tunnel_status() {
  clear
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    read -rp "📥 Press Enter to return to main menu..."
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | head -1 | cut -d'"' -f2)
  local REMOTE_ADDR=$(grep '^remote_addr = ' "$CONFIG_PATH" | cut -d'"' -f2)
  local BIND_ADDR=$(grep '^bind_addr = ' "$CONFIG_PATH" | cut -d'"' -f2)

  local HOST=""
  local PORT=""

  if [[ -n "$REMOTE_ADDR" ]]; then
    HOST=$(echo "$REMOTE_ADDR" | cut -d':' -f1)
    PORT=$(echo "$REMOTE_ADDR" | cut -d':' -f2)
    echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
    echo -e "🌐 Connected to Server: ${YELLOW}$HOST on port $PORT${RESET}"
    echo -e "⏳ Pinging $HOST to check tunnel connectivity..."
  elif [[ -n "$BIND_ADDR" ]]; then
    HOST="8.8.8.8"
    echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
    echo -e "🌐 Running as Server: ${YELLOW}$BIND_ADDR${RESET}"
    echo -e "⏳ Pinging $HOST to check internet connectivity..."
  else
    echo -e "${RED}❌ Could not determine tunnel IP.${RESET}"
    read -rp "📥 Press Enter to return to main menu..."
    return
  fi

  local AVG_PING=$(get_average_ping "$HOST")

  if [ "$AVG_PING" == "N/A" ]; then
    echo -e "${RED}❌ Host $HOST is unreachable.${RESET}"
  else
    echo -e "✅ Host is reachable. Average ping: ${GREEN}${AVG_PING} ms${RESET}"
  fi

  read -rp "📥 Press Enter to return to main menu..."
}

function restart_backhaul_service() {
  clear
  echo -e "${YELLOW}🔄 Restarting Backhaul service...${RESET}"
  sudo systemctl restart backhaul.service
  sleep 1
  echo -e "${GREEN}✅ Backhaul service restarted.${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function show_logs() {
  clear
  echo -e "${CYAN}📜 Showing Backhaul service logs. Press Ctrl+C to return.${RESET}"
  sudo journalctl -u backhaul.service -e -f
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
    echo -e "  8) 🚪 Exit"
    echo -ne "\n  📝 Select option (1-8): "
    read -r CHOICE

    case "$CHOICE" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) restart_backhaul_service ;;
      7) show_logs ;;
      8) clear; echo -e "${CYAN}👋 Goodbye!${RESET}"; exit 0 ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1 ;;
    esac
  done
}

main_menu
