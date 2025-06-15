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
  echo -e "${CYAN}🌍 Iran Server Installation${RESET}"
  read -rp "🔑 Enter token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  while true; do
    read -rp "🔌 Enter tunnel port (default: 64320): " TUNNEL_PORT
    TUNNEL_PORT=${TUNNEL_PORT:-64320}
    if [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]]; then
      break
    else
      echo -e "${RED}❌ Invalid port number. Try again.${RESET}"
    fi
  done

  echo -e "${YELLOW}📦 Enter ports one per line (e.g., 80). Press Enter empty to finish.${RESET}"
  PORTS=()
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      echo -e "${RED}❌ Invalid port number. Try again.${RESET}"
      continue
    fi
    if printf '%s\n' "${PORTS[@]}" | grep -qx "$PORT"; then
      echo -e "${YELLOW}⚠️ Port $PORT already entered. Enter a different port.${RESET}"
      continue
    fi
    PORTS+=("$PORT")
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update -qq > /dev/null 2>&1 && apt install -y -qq wget tar > /dev/null 2>&1

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS_ARRAY="["
  for p in "${PORTS[@]}"; do
    PORTS_ARRAY+="
  \"$p\","
  done
  PORTS_ARRAY+="
]"

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
ports = $PORTS_ARRAY
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

  # پاک کردن فایل‌های اضافی بعد نصب
  rm -f backhaul_linux_amd64.tar.gz README.md LICENSE

  echo -e "${GREEN}✅ Iran server started on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function install_europe_client() {
  clear
  echo -e "${CYAN}🌐 Europe Client Installation${RESET}"
  read -rp "🔑 Enter token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  while true; do
    read -rp "🌐 Enter server IP or hostname: " SERVER_IP
    if [[ -n "$SERVER_IP" ]]; then
      break
    else
      echo -e "${RED}❌ IP/hostname cannot be empty.${RESET}"
    fi
  done

  while true; do
    read -rp "🔌 Enter tunnel port (default: 64320): " TUNNEL_PORT
    TUNNEL_PORT=${TUNNEL_PORT:-64320}
    if [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]]; then
      break
    else
      echo -e "${RED}❌ Invalid port number. Try again.${RESET}"
    fi
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update -qq > /dev/null 2>&1 && apt install -y -qq wget tar > /dev/null 2>&1

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

  # پاک کردن فایل‌های اضافی بعد نصب
  rm -f backhaul_linux_amd64.tar.gz README.md LICENSE

  echo -e "${GREEN}✅ Europe client started connecting to $SERVER_IP on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function edit_tunnel_menu() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  1) 🟢 Edit Iran-Server Config"
  echo -e "  2) 🔵 Edit Europe-Client Config"
  echo -e "  3) 🔙 Back to Main Menu"
  read -rp "📝 Select option (1-3): " SUB_CHOICE
  case "$SUB_CHOICE" in
    1) edit_server_config ;;
    2) edit_client_config ;;
    3) main_menu ;;
    *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1; edit_tunnel_menu ;;
  esac
}

function edit_server_config() {
  nano "$CONFIG_PATH"
  echo -e "📥 Press Enter to return to Tunnel Configuration Menu..."
  read -r
  edit_tunnel_menu
}

function edit_client_config() {
  nano "$CONFIG_PATH"
  echo -e "📥 Press Enter to return to Tunnel Configuration Menu..."
  read -r
  edit_tunnel_menu
}

function show_tunnel_status() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    echo -e "📥 Press Enter to return to main menu..."
    read -r
    main_menu
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | cut -d'"' -f2)
  local IP=$(grep -E '^remote_addr =|bind_addr =' "$CONFIG_PATH" | cut -d'"' -f2)
  local PORT=$(echo "$IP" | cut -d: -f2)
  local HOST=$(echo "$IP" | cut -d: -f1)

  echo -e "🔑 Token: ${YELLOW}$TOKEN${RESET}"
  echo -e "🌐 IP: ${YELLOW}$HOST${RESET}"
  echo -e "🔌 Port: ${YELLOW}$PORT${RESET}"

  echo -e "⏳ Pinging $HOST to check tunnel connectivity..."

  if [[ "$HOST" == "0.0.0.0" ]]; then
    # For Iran server, ping Google DNS
    PING_TARGET="8.8.8.8"
  else
    PING_TARGET="$HOST"
  fi

  if ping -c 4 -q "$PING_TARGET" > /tmp/ping_result 2>&1; then
    AVG=$(grep 'rtt min/avg/max/mdev' /tmp/ping_result | awk -F '/' '{print $5}')
    echo -e "✅ Tunnel server is reachable. Average ping: ${GREEN}${AVG} ms${RESET}"
  else
    echo -e "${RED}❌ Tunnel server is unreachable.${RESET}"
  fi

  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function clean_backhaul_files() {
  clear
  echo -e "${YELLOW}🧹 Cleaning Backhaul files...${RESET}"
  
  read -rp "❓ Are you sure you want to delete backhaul files? (y/n): " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    systemctl stop backhaul 2>/dev/null
    rm -f /root/backhaul /root/config.toml /root/backhaul.json /etc/systemd/system/backhaul.service backhaul_linux_amd64.tar.gz README.md LICENSE
    systemctl daemon-reload
    systemctl disable backhaul 2>/dev/null
    echo -e "${GREEN}✅ Clean complete.${RESET}"
  else
    echo -e "${YELLOW}⚠️ Clean cancelled.${RESET}"
  fi

  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function show_logs() {
  clear
  echo -e "${CYAN}📜 Showing backhaul.service logs (press Ctrl+C to exit)...${RESET}"
  journalctl -u backhaul.service -f
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function restart_tunnel() {
  clear
  echo -e "${YELLOW}🔄 Restarting backhaul service...${RESET}"
  systemctl restart backhaul
  sleep 2
  systemctl status backhaul --no-pager
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function show_help() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📚 Guide & Notes:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "🔑 The token of both servers must be the same"
  echo -e "🔌 The tunnel port of both servers must be the same"
  echo -e "🧹 Before creating the tunnel, select option 4 and delete the files (if you already have a tunnel)"
  echo -e "💡 Use clean option if you want to reset the setup"
  echo -e "\n📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function about() {
  clear
  echo -e "${CYAN}Created by HR⚡${RESET}"
  echo -e "\n📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function main_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🌍 Please select an option:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  0) ⚡ About"
    echo -e "  1) 💚 Install Iran-Server"
    echo -e "  2) ❤️ Install Europe-Client"
    echo -e "  3) ⚙️ Edit Tunnel Config"
    echo -e "  4) 🧹 Clean Backhaul Files"
    echo -e "  5) 📡 Tunnel Status"
    echo -e "  6) 📜 Show Logs"
    echo -e "  7) 🔄 Restart Tunnel"
    echo -e "  8) 📚 Guide & Help"
    echo -e "  9) ❌ Exit"
    echo -ne "\n   📝 Select option (0-9): "
    read -r CHOICE
    case "$CHOICE" in
      0) about ;;
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) show_logs ;;
      7) restart_tunnel ;;
      8) show_help ;;
      9) clear; exit 0 ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1 ;;
    esac
  done
}

main_menu
