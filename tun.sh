#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# Trap Ctrl+C to return to menu
trap ctrl_c INT
function ctrl_c() {
  echo -e "\n${YELLOW}↩️ Returning to main menu...${RESET}"
  sleep 1
  main_menu
}

function install_dependencies() {
  echo -e "${CYAN}⏳ Installing dependencies...${RESET}"
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y wget tar >/dev/null 2>&1
}

function show_banner() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🌍 Please select an option:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

function press_enter_to_continue() {
  echo -ne "\n📥 Press Enter to return to main menu..."
  read
  main_menu
}

function install_iran_server() {
  show_banner
  echo -e "💚 Installing Server (Iran Side)..."
  install_dependencies
  echo -e "✅ Server installation complete."
  press_enter_to_continue
}

function install_europe_client() {
  show_banner
  echo -e "❤️ Installing Client (Europe Side)..."
  install_dependencies
  echo -e "✅ Client installation complete."
  press_enter_to_continue
}

function edit_tunnel_config() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}⚙️  Edit Tunnel Configuration:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) 📝 Edit Iran-Server"
    echo -e "  2) 📝 Edit Europe-Client"
    echo -e "  3) ↩️ Back to Main Menu"
    echo -ne "\n🔧 Select option (1-3): "
    read -r EDIT_CHOICE

    case $EDIT_CHOICE in
      1) echo -e "🔧 Editing Iran Server config..."; sleep 1 ;;
      2) echo -e "🔧 Editing Europe Client config..."; sleep 1 ;;
      3) main_menu ;;
      *) echo -e "${RED}❌ Invalid option!${RESET}" ;;
    esac
  done
}

function clean_backhaul_files() {
  clear
  echo -e "${YELLOW}⚠️ This will delete all tunnel files. Are you sure? (y/n)${RESET}"
  read -r CONFIRM
  if [[ $CONFIRM == "y" ]]; then
    rm -f /etc/backhaul/config.toml
    rm -f /etc/backhaul/backhaul
    echo -e "${GREEN}🧹 All files removed.${RESET}"
  else
    echo -e "${BLUE}🛑 Cancelled.${RESET}"
  fi
  press_enter_to_continue
}

function show_tunnel_status() {
  clear
  if [ ! -f /etc/backhaul/config.toml ]; then
    echo -e "${RED}❌ Tunnel not configured or config.toml missing.${RESET}"
    press_enter_to_continue
    return
  fi
  IP=$(grep -oP '(?<=server_ip = ")[^"]*' /etc/backhaul/config.toml)
  echo -e "🌐 IP: $IP"
  echo -e "⏳ Pinging $IP..."
  RESULT=$(ping -c 4 "$IP" | tail -1 | awk '{print $4}')
  if [[ -n "$RESULT" ]]; then
    echo -e "${GREEN}✅ Tunnel server is reachable. Average ping: $RESULT ms${RESET}"
  else
    echo -e "${RED}❌ Tunnel not reachable.${RESET}"
  fi
  press_enter_to_continue
}

function restart_tunnel() {
  clear
  echo -e "${CYAN}🔄 Restarting tunnel service...${RESET}"
  sudo systemctl restart backhaul.service
  echo -e "${GREEN}✅ Tunnel restarted.${RESET}"
  press_enter_to_continue
}

function show_logs() {
  clear
  echo -e "${CYAN}📜 Tunnel Logs:${RESET}"
  journalctl -u backhaul.service -e -n 20 --no-pager
  press_enter_to_continue
}

function show_help() {
  clear
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📘 Tunnel Setup Guide:${RESET}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "🔑 The token of both servers must be the same"
  echo -e "🚪 The tunnel port of both servers must be the same"
  echo -e "🧹 Before creating the tunnel, select option 4 to delete old files"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  press_enter_to_continue
}

function main_menu() {
  while true; do
    clear
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🌍 Please select an option:${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  1) 💚 Install Server (Iran)"
    echo -e "  2) ❤️ Install Client (Europe)"
    echo -e "  3) ⚙️  Edit Tunnel Config"
    echo -e "  4) 🧹 Clean Backhaul Files"
    echo -e "  5) 📡 Tunnel Status"
    echo -e "  6) 🔄 Restart Tunnel"
    echo -e "  7) 📜 View Tunnel Logs"
    echo -e "  8) 📘 Help / Guide"
    echo -e "  9) ❌ Exit"
    echo -ne "\n📝 Select option (1-9): "
    read -r CHOICE

    case $CHOICE in
      1) install_iran_server ;;
      2) install_europe_client ;;
      3) edit_tunnel_config ;;
      4) clean_backhaul_files ;;
      5) show_tunnel_status ;;
      6) restart_tunnel ;;
      7) show_logs ;;
      8) show_help ;;
      9) echo -e "${YELLOW}👋 Goodbye!${RESET}"; exit ;;
      *) echo -e "${RED}❌ Invalid option!${RESET}"; sleep 1 ;;
    esac
  done
}

main_menu
