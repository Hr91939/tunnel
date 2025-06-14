#!/bin/bash

# Colors for nicer output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

clear
echo -e "${CYAN}🌍 Please select your country:${RESET}"
echo -e "  1) IR: ${GREEN}Iran-Server${RESET}"
echo -e "  2) EU: ${GREEN}Europe-Client${RESET}"
read -rp "📝 Selected number (1 or 2): " MODE

if [[ "$MODE" == "1" ]]; then
  echo -e "${GREEN}✅ Iran server settings are running...${RESET}"

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  echo -e "${YELLOW}📦 Enter the ports one per line (just the number, e.g., 80).${RESET}"
  echo -e "🔚 Press Enter on empty line to finish."
  PORTS=""
  while true; do
    read -rp "➡️ Port: " PORT
    [[ -z "$PORT" ]] && break
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      echo -e "${RED}❌ Invalid port number, please enter digits only.${RESET}"
      continue
    fi
    PORTS+="\"$PORT\",\n"
  done

  echo -e "${CYAN}⏳ Installing requirements and downloading Backhaul...${RESET}"
  apt update && apt install -y wget tar

  cd /root || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  cat > /root/config.toml <<EOF
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
$(printf "$PORTS")
]
EOF

  cat > /etc/systemd/system/backhaul.service <<EOF
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

  echo -e "${GREEN}✅ Backhaul server started on port $TUNNEL_PORT with your selected ports and token \"$TOKEN\".${RESET}"

elif [[ "$MODE" == "2" ]]; then
  if [ ! -t 0 ]; then
    echo -e "${RED}❌ The environment is non-interactive and the IP cannot be queried. Execution stopped.${RESET}"
    exit 1
  fi

  read -rp "🌐 Please enter the Iran server IP: " SERVER_IP
  if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}❌ IP not entered. Logout...${RESET}"
    exit 1
  fi

  read -rp "🔌 Enter the tunnel port (default: 64320): " TUNNEL_PORT
  TUNNEL_PORT=${TUNNEL_PORT:-64320}

  read -rp "🔑 Enter the token (default: hr): " TOKEN
  TOKEN=${TOKEN:-hr}

  echo -e "${GREEN}✅ European client settings are running...${RESET}"

  apt update && apt install -y wget tar

  cd /root || exit
  wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
  tar -xzf backhaul_linux_amd64.tar.gz

  cat > /root/config.toml <<EOF
[client]
remote_addr = "$SERVER_IP:$TUNNEL_PORT"
transport = "tcp"
token = "$TOKEN"
connection_pool = 512
aggressive_pool = false
keepalive_period = 75
dial_timeout = 10
nodelay = true
retry_interval = 3
sniffer = false
web_port = 2060
sniffer_log = "/root/backhaul.json"
log_level = "info"
EOF

  cat > /etc/systemd/system/backhaul.service <<EOF
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

  echo -e "${GREEN}✅ Backhaul client connected to $SERVER_IP:$TUNNEL_PORT with token \"$TOKEN\" and the service was activated.${RESET}"

else
  echo -e "${RED}❌ The selection was invalid. Please enter only the number 1 or 2.${RESET}"
  exit 1
fi
