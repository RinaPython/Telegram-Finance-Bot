#!/bin/bash

# ============================================================
# FINANCE BOT — DASHBOARD
# Version: 2.0.0
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR" || exit 1

if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    for dir in "$HOME/Telegram-Finance-Bot" "$HOME/finance-bot" "/opt/finance-bot"; do
        if [ -f "$dir/docker-compose.yml" ]; then
            PROJECT_DIR="$dir"
            cd "$PROJECT_DIR" || exit 1
            break
        fi
    done
fi

get_status() {
    if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "finance-bot"; then
        echo -e "${GREEN}RUNNING${NC}"
    else
        echo -e "${RED}STOPPED${NC}"
    fi
}

get_uptime() {
    docker ps --format "{{.Status}}" --filter "name=finance-bot" 2>/dev/null || echo "N/A"
}

get_health() {
    local h=$(docker inspect --format='{{.State.Health.Status}}' finance-bot 2>/dev/null)
    if [ "$h" = "healthy" ]; then
        echo -e "${GREEN}HEALTHY${NC}"
    elif [ "$h" = "unhealthy" ]; then
        echo -e "${RED}UNHEALTHY${NC}"
    else
        echo -e "${YELLOW}$h${NC}"
    fi
}

draw_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}              FINANCE BOT SERVER${NC}${CYAN}                         ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Status VPS : ${WHITE}$(uptime -p | sed 's/up //')${NC}${CYAN}                        ║${NC}"
    echo -e "${CYAN}║${NC}  Bot Status : $(get_status)${CYAN}                                          ║${NC}"
    echo -e "${CYAN}║${NC}  Uptime     : ${WHITE}$(get_uptime)${NC}${CYAN}                             ║${NC}"
    echo -e "${CYAN}║${NC}  Health     : $(get_health)${CYAN}                                         ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1.${NC} START BOT                                      ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${RED}2.${NC} STOP BOT                                       ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}3.${NC} RESTART BOT                                    ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}4.${NC} REBUILD & START BOT                            ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}5.${NC} BOT STATUS                                     ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}6.${NC} VIEW LOG                                      ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}7.${NC} SYSTEM STATUS                                 ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}8.${NC} REFRESH DASHBOARD                             ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${RED}9.${NC} REBOOT VPS                                    ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}10.${NC} UPDATE FROM GITHUB                            ${CYAN}│${NC}"
    echo -e "${CYAN}║${NC}  ${RED}0.${NC} EXIT                                          ${CYAN}│${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${WHITE}Pilih opsi [0-10]: ${NC}"
}

start_bot() {
    echo -e "${YELLOW}Menjalankan bot...${NC}"
    docker compose up -d
    echo -e "${GREEN}Selesai${NC}"
    sleep 1
}

stop_bot() {
    echo -e "${YELLOW}Menghentikan bot...${NC}"
    docker compose down
    echo -e "${GREEN}Selesai${NC}"
    sleep 1
}

restart_bot() {
    echo -e "${YELLOW}Merestart bot...${NC}"
    docker compose restart
    echo -e "${GREEN}Selesai${NC}"
    sleep 2
}

rebuild_bot() {
    echo -e "${YELLOW}Membangun ulang bot...${NC}"
    docker compose down
    docker compose build --no-cache
    docker compose up -d
    echo -e "${GREEN}Selesai${NC}"
    sleep 2
}

view_logs() {
    echo -e "${YELLOW}Log (50 baris terakhir):${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    docker compose logs --tail=50
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk kembali...${NC}"
    read
}

system_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}              SYSTEM STATUS${NC}${CYAN}                                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}OS:${NC} $(lsb_release -ds 2>/dev/null || echo "Unknown")"
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo -e "${WHITE}CPU:${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "${WHITE}RAM:${NC} $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo -e "${WHITE}Disk:${NC} $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo ""
    echo -e "${WHITE}Docker:${NC} $(docker --version 2>/dev/null | head -1 || echo "Not installed")"
    echo -e "${WHITE}Docker Compose:${NC} $(docker-compose --version 2>/dev/null | head -1 || echo "Not installed")"
    echo ""
    echo -e "${WHITE}Container:${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "finance-bot|NAMES" || echo "  No containers"
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk kembali...${NC}"
    read
}

reboot_vps() {
    echo ""
    echo -e "${RED}${BOLD}⚠️  PERINGATAN: VPS akan direboot!${NC}"
    echo -ne "${WHITE}Lanjutkan? [y/N]: ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Merestart VPS...${NC}"
        sudo reboot
    else
        echo -e "${YELLOW}Dibatalkan${NC}"
        sleep 1
    fi
}

update_github() {
    echo -e "${YELLOW}Mengupdate dari GitHub...${NC}"
    git pull
    docker compose down
    docker compose build --no-cache
    docker compose up -d
    echo -e "${GREEN}Selesai${NC}"
    sleep 2
}

while true; do
    draw_menu
    read choice
    
    case $choice in
        1) start_bot ;;
        2) stop_bot ;;
        3) restart_bot ;;
        4) rebuild_bot ;;
        5) 
            echo ""
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "finance-bot|NAMES"
            echo ""
            echo -ne "${WHITE}Tekan Enter untuk kembali...${NC}"
            read
            ;;
        6) view_logs ;;
        7) system_status ;;
        8) continue ;;
        9) reboot_vps ;;
        10) update_github ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opsi tidak valid${NC}"
            sleep 1
            ;;
    esac
done