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
  echo -e "${CYAN}💚 Installing Iran Server...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  while true; do
    read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
    TUNNEL_PORT=${TUNNEL_PORT:-64320}
    if [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]]; then
      break
    else
      echo -e "${RED}❌ Invalid port, try again.${RESET}"
    fi
  done

  echo -e "${YELLOW}📥 Enter the ports (one per line). Press Enter on empty line to finish.${RESET}"

  PORTS=()
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      echo -e "${RED}❌ Invalid port.${RESET}"
      continue
    fi
    if [[ " ${PORTS[*]} " == *" $PORT "* ]]; then
      echo -e "${RED}❌ Duplicate port.${RESET}"
      continue
    fi
    PORTS+=("$PORT")
  done

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update -qq >/dev/null 2>&1 || { echo -e "${RED}Failed to update packages.${RESET}"; exit 1; }
  apt install -y wget tar -qq >/dev/null 2>&1 || { echo -e "${RED}Failed to install packages.${RESET}"; exit 1; }

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  PORTS_ARRAY=""
  for p in "${PORTS[@]}"; do
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
$PORTS_ARRAY
]
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

  echo -e "${GREEN}✅ Iran Server started on port $TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function install_europe_client() {
  echo -e "${CYAN}❤️ Installing Europe Client...${RESET}"

  read -rp "🔑 Enter the token (must be same as server): " TOKEN

  while true; do
    read -rp "🔌 Enter tunnel port (must be same as server): " TUNNEL_PORT
    if [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]]; then
      break
    else
      echo -e "${RED}❌ Invalid port, try again.${RESET}"
    fi
  done

  read -rp "🌐 Enter Server IP or domain: " SERVER_IP

  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt update -qq >/dev/null 2>&1 || { echo -e "${RED}Failed to update packages.${RESET}"; exit 1; }
  apt install -y wget tar -qq >/dev/null 2>&1 || { echo -e "${RED}Failed to install packages.${RESET}"; exit 1; }

  cd "$BACKHAUL_DIR" || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  cat > "$CONFIG_PATH" <<EOF
[client]
remote_addr = "$SERVER_IP:$TUNNEL_PORT"
token = "$TOKEN"
local_udp_port = 0
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
  systemctl restart backhaul

  echo -e "${GREEN}✅ Europe Client connected to $SERVER_IP:$TUNNEL_PORT with token \"$TOKEN\".${RESET}"
  read -rp "📥 Press Enter to return to main menu..."
}

function edit_tunnel_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}⚙️ Edit Tunnel Config${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "1) 🔑 Edit Token"
    echo -e "2) 🔌 Edit Tunnel Port"
    echo -e "3) 📥 Edit Ports (Iran Server Only)"
    echo -e "4) 🔙 Back to Main Menu"
    echo -ne "\n📝 Select option (1-4): "
    read -r opt

    case "$opt" in
      1) edit_token ;;
      2) edit_port ;;
      3) edit_ports ;;
      4) break ;;
      *) echo -e "${RED}❌ Invalid option.${RESET}" ; sleep 1 ;;
    esac
  done
}

function edit_token() {
  read -rp "🔑 Enter new token: " NEW_TOKEN
  if grep -q "token" "$CONFIG_PATH"; then
    sed -i "s/^token = .*/token = \"$NEW_TOKEN\"/" "$CONFIG_PATH"
  else
    echo "token = \"$NEW_TOKEN\"" >> "$CONFIG_PATH"
  fi
  echo -e "${GREEN}✅ Token updated.${RESET}"
  read -rp "📥 Press Enter to continue..."
}

function edit_port() {
  while true; do
    read -rp "🔌 Enter new tunnel port: " NEW_PORT
    if [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
      if grep -q "bind_addr" "$CONFIG_PATH"; then
        sed -i "s/^bind_addr = .*/bind_addr = \"0.0.0.0:$NEW_PORT\"/" "$CONFIG_PATH"
      else
        echo "bind_addr = \"0.0.0.0:$NEW_PORT\"" >> "$CONFIG_PATH"
      fi
      echo -e "${GREEN}✅ Tunnel port updated.${RESET}"
      break
    else
      echo -e "${RED}❌ Invalid port.${RESET}"
    fi
  done
  read -rp "📥 Press Enter to continue..."
}

function edit_ports() {
  echo -e "${YELLOW}📥 Enter new ports (one per line). Empty line to finish.${RESET}"

  NEW_PORTS=()
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      echo -e "${RED}❌ Invalid port.${RESET}"
      continue
    fi
    if [[ " ${NEW_PORTS[*]} " == *" $PORT "* ]]; then
      echo -e "${RED}❌ Duplicate port.${RESET}"
      continue
    fi
    NEW_PORTS+=("$PORT")
  done

  # Build ports block with commas
  PORTS_ARRAY=""
  for p in "${NEW_PORTS[@]}"; do
    PORTS_ARRAY+="\"$p\",\n"
  done

  # Replace ports block in config.toml
  # Use sed to replace between ports = [ ... ]
  sed -i '/ports = \[/,/\]/c\ports = [\n'"$PORTS_ARRAY"']' "$CONFIG_PATH"

  echo -e "${GREEN}✅ Ports updated.${RESET}"
  read -rp "📥 Press Enter to continue..."
}

function clean_backhaul_files() {
  read -rp "⚠️ Are you sure to delete all backhaul files? Type 'yes' to confirm: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}Operation cancelled.${RESET}"
    read -rp "📥 Press Enter to continue..."
    return
  fi
  echo -e "${YELLOW}🧹 Cleaning files...${RESET}"
  rm -f "$BACKHAUL_DIR"/backhaul_linux_amd64.tar.gz "$BACKHAUL_DIR"/backhaul.json "$CONFIG_PATH" /root/LICENSE /root/README.md
  echo -e "${GREEN}✅ Files removed.${RESET}"
  read -rp "📥 Press Enter to continue..."
}

function show_tunnel_status() {
  clear
  echo -e "${CYAN}📡 Checking Tunnel Status...${RESET}"

  if ! systemctl is-active --quiet backhaul; then
    echo -e "${RED}❌ Backhaul service is not running.${RESET}"
    read -rp "📥 Press Enter to return..."
    return
  fi

  if grep -q "\[server\]" "$CONFIG_PATH"; then
    # Iran server
    PORT=$(grep 'bind_addr' "$CONFIG_PATH" | grep -oP '\d+$')
    IP="8.8.8.8"
  else
    # Europe client
    IP=$(grep 'remote_addr' "$CONFIG_PATH" | cut -d '"' -f2 | cut -d ':' -f1)
    PORT=$(grep 'remote_addr' "$CONFIG_PATH" | cut -d '"' -f2 | cut -d ':' -f2)
  fi

  echo -e "Connecting to server: ${YELLOW}$IP${RESET} on port ${YELLOW}$PORT${RESET}"

  echo -e "⏳ Pinging $IP to check tunnel connectivity..."

  # Ping 4 times and get average time
  PING_OUTPUT=$(ping -c 4 "$IP" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Unable to reach $IP.${RESET}"
  else
    AVG=$(echo "$PING_OUTPUT" | tail -1 | awk -F '/' '{print $5}')
    echo -e "✅ Tunnel server is reachable. Average ping: ${GREEN}${AVG} ms${RESET}"
  fi

  read -rp "📥 Press Enter to return to main menu..."
}

function view_logs() {
  clear
  echo -e "${CYAN}📖 Showing Backhaul logs. Press Ctrl+C or Enter to exit.${RESET}"
  echo ""
  # Show last 30 lines and follow logs
  journalctl -u backhaul.service -n 30 -f &
  PID=$!

  # Wait for user to press Enter to quit logs
  read -r
  kill "$PID" 2>/dev/null
}

function restart_tunnel() {
  echo -e "${YELLOW}🔄 Restarting Backhaul service...${RESET}"
  systemctl restart backhaul
  echo -e "${GREEN}✅ Backhaul service restarted.${RESET}"
  read -rp "📥 Press Enter to continue..."
}

function show_help() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🆘 Backhaul Management Script Help${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  cat <<EOF
این اسکریپت به شما امکان می‌دهد که یک تونل معکوس Backhaul را به‌راحتی روی سرور ایران (Server) یا کلاینت اروپا نصب و مدیریت کنید.

🟢 نصب ایران سرور:
  - تنظیم توکن امنیتی
  - تنظیم پورت تونل
  - انتخاب پورت‌های عبوری

🔵 نصب اروپا کلاینت:
  - اتصال به سرور ایران با توکن و پورت صحیح

⚙️ امکانات مدیریت:
  - ویرایش تنظیمات تونل (توکن، پورت، پورت‌ها)
  - نمایش وضعیت تونل و پینگ سرور
  - مشاهده لاگ‌های سرویس
  - ریستارت سرویس تونل
  - پاک‌سازی فایل‌ها

📌 نکات مهم:
  - توکن باید بین سرور و کلاینت یکسان باشد.
  - در حالت سرور، امکان تنظیم چند پورت وجود دارد.
  - بعد از هر تغییر، سرویس به صورت خودکار ریستارت می‌شود.

EOF
  read -rp "📥 Press Enter to return..."
}

function main_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🌐 Backhaul Tunnel Manager - Main Menu${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "1) 🇮🇷 Install Iran Server"
    echo -e "2) 🇪🇺 Install Europe Client"
    echo -e "3) ⚙️ Edit Tunnel Config"
    echo -e "4) 📡 Show Tunnel Status"
    echo -e "5) 📖 View Logs"
    echo -e "6) 🔄 Restart Tunnel"
    echo -e "7) 🧹 Clean Backhaul Files"
    echo -e "8) 🆘 Help / About"
    echo -e "9) 🚪 Exit"
    echo -ne "\nSelect an option (1-9): "
    read -r choice

    case "$choice" in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_menu ;;
      4) show_tunnel_status ;;
      5) view_logs ;;
      6) restart_tunnel ;;
      7) clean_backhaul_files ;;
      8) show_help ;;
      9) echo -e "${YELLOW}Goodbye!${RESET}" ; exit 0 ;;
      *) echo -e "${RED}❌ Invalid option.${RESET}" ; sleep 1 ;;
    esac
  done
}

# Run main menu
main_menu
