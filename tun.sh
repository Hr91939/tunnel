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
    if [[ " ${PORTS[*]} " == *" $PORT "* ]]; then
      echo -e "${YELLOW}⚠️ Port $PORT already entered. Enter a different port.${RESET}"
      continue
    fi
    PORTS+=("$PORT")
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update && apt install -y wget tar

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS_ARRAY=$(printf '"%s",' "${PORTS[@]}")
  PORTS_ARRAY="[${PORTS_ARRAY%,}]"

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

  echo -e "${GREEN}✅ Iran server started on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function install_europe_client() {
  clear
  echo -e "${CYAN}🌍 Europe Client Installation${RESET}"

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

  read -rp "🌐 Enter server IP: " SERVER_IP

  cat > "$CONFIG_PATH" <<EOF
[client]
remote_addr = "$SERVER_IP:$TUNNEL_PORT"
token = "$TOKEN"
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

  echo -e "${GREEN}✅ Europe client started connecting to $SERVER_IP on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function edit_server_config() {
  clear
  echo -e "${CYAN}📝 Editing Iran Server Config File...${RESET}"
  nano "$CONFIG_PATH"
  echo -e "📥 Press Enter to return to Tunnel Config Menu..."
  read -r
  edit_tunnel_menu
}

function edit_client_config() {
  clear
  echo -e "${CYAN}📝 Editing Europe Client Config File...${RESET}"
  nano "$CONFIG_PATH"
  echo -e "📥 Press Enter to return to Tunnel Config Menu..."
  read -r
  edit_tunnel_menu
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}⚙️ Tunnel Configuration Menu:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) ✏️ Edit Iran Server Config"
    echo -e "  2) ✏️ Edit Europe Client Config"
    echo -e "  3) 🔙 Back to Main Menu"
    echo -ne "\n📝 Select option (1-3): "
    read -r SUB_CHOICE
    case "$SUB_CHOICE" in
      1) edit_server_config ;;
      2) edit_client_config ;;
      3) main_menu; break ;;
      *) echo -e "${RED}❌ Invalid selection.${RESET}" ;;
    esac
  done
}

function show_tunnel_status() {
  clear
  echo -e "${CYAN}📡 Tunnel Status:${RESET}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}❌ Tunnel is not connected. Configuration file not found.${RESET}"
    echo -e "📥 Press Enter to return to main menu..."
    read -r
    main_menu
    return
  fi

  local TOKEN=$(grep '^token = ' "$CONFIG_PATH" | cut -d'"' -f2)
  local IP_LINE=$(grep -E '^remote_addr =|bind_addr =' "$CONFIG_PATH" | cut -d'"' -f2)

  if [[ "$IP_LINE" == 0.0.0.0* || -z "$IP_LINE" ]]; then
    # Iran server - ping 8.8.8.8
    PING_HOST="8.8.8.8"
    echo -e "⏳ Pinging $PING_HOST to check tunnel connectivity..."
  else
    # Europe client - ping to IP from config
    PING_HOST=$(echo "$IP_LINE" | cut -d: -f1)
    echo -e "⏳ Pinging $PING_HOST to check tunnel connectivity..."
  fi

  # Perform ping and calculate average of first 4 pings
  PING_RESULT=$(ping -c 4 -W 2 "$PING_HOST" 2>/dev/null | tail -1)
  if [ -z "$PING_RESULT" ]; then
    echo -e "${RED}❌ Tunnel server is not reachable.${RESET}"
    echo -e "📥 Press Enter to return to main menu..."
    read -r
    main_menu
    return
  fi

  AVG_PING=$(echo "$PING_RESULT" | awk -F '/' '{print $5}')

  echo -e "${GREEN}✅ Tunnel server is reachable.${RESET} Average ping: ${YELLOW}${AVG_PING} ms${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function clean_backhaul_files() {
  clear
  read -rp "⚠️ Are you sure you want to remove all Backhaul files? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}❗ Operation cancelled.${RESET}"
    echo -e "📥 Press Enter to return to main menu..."
    read -r
    main_menu
    return
  fi

  echo -e "${YELLOW}🧹 Cleaning Backhaul files...${RESET}"
  rm -f "$BACKHAUL_DIR"/backhaul_linux_amd64.tar.gz
  rm -f "$BACKHAUL_DIR"/backhaul.json
  rm -f "$CONFIG_PATH"
  rm -f /root/LICENSE
  rm -f /root/README.md
  echo -e "${GREEN}✅ Files cleaned.${RESET}"
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function show_logs() {
  clear
  echo -e "${CYAN}📜 Showing Backhaul service logs... (Press Ctrl+C to exit)${RESET}"
  echo
  # Show last 20 lines and follow
  journalctl -u backhaul.service -n 20 -f
  echo -e "\n📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function restart_tunnel() {
  clear
  echo -e "${CYAN}🔄 Restarting Backhaul service...${RESET}"
  systemctl restart backhaul
  sleep 2
  systemctl status backhaul -n 10 --no-pager
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function show_help() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🆘 Backhaul Setup Help${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "🔑 ${YELLOW}Token of both servers must be the same.${RESET}"
  echo -e "🔌 ${YELLOW}Tunnel port of both servers must be the same.${RESET}"
  echo -e "🧹 ${YELLOW}Before creating the tunnel, select option 4 and delete old files if you have an existing tunnel.${RESET}"
  echo -e "📄 For config files, you can edit using option 3."
  echo -e "🔄 Use option 7 to restart the tunnel service."
  echo -e "📜 Use option 6 to view logs and debug issues."
  echo -e "📥 Press Enter to return to main menu..."
  read -r
  main_menu
}

function main_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🌐 Backhaul Tunnel Management${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) 💚 Install Iran Server"
    echo -e "  2) ❤️ Install Europe Client"
    echo -e "  3) ⚙️ Edit Tunnel Config"
    echo -e "  4) 🧹 Clean Backhaul Files"
    echo -e "  5) 📡 Tunnel Status"
    echo -e "  6) 📜 Show Logs"
    echo -e "  7) 🔄 Restart Tunnel"
    echo -e "  8) 🆘 Help & Instructions"
    echo -e "  9) ❌ Exit"
    echo -ne "\n📝 Select option (1-9): "
    read -r CHOICE

    case "$CHOICE" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) show_logs ;;
      7) restart_tunnel ;;
      8) show_help ;;
      9) echo -e "${CYAN}👋 Bye!${RESET}"; exit 0 ;;
      *) echo -e "${RED}❌ Invalid selection. Try again.${RESET}" ;;
    esac
  done
}

# Start the script by showing the main menu
main_menu
