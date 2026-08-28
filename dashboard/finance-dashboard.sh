#!/bin/bash

# ============================================================
# DASHBOARD & PANEL KONTROL SERVER BOT KEUANGAN
# Versi: 3.1.0
# Lokasi: /usr/local/bin/finance-dashboard.sh
# ============================================================

# ============================================================
# KONFIGURASI
# ============================================================

PROJECT_DIR="$HOME/Telegram-Finance-Bot"
CONTAINER_NAME="finance-bot"
LOG_LINES=50

# Warna ANSI
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Lebar box (total lebar karakter)
BOX_W=52
INNER_W=48

# ============================================================
# FUNGSI DETEKSI
# ============================================================

detect_project_dir() {
    if [ -d "$HOME/Telegram-Finance-Bot" ]; then
        echo "$HOME/Telegram-Finance-Bot"
    elif [ -d "$HOME/finance-bot" ]; then
        echo "$HOME/finance-bot"
    else
        echo ""
    fi
}

detect_container_name() {
    local name=$(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -E "finance-bot|bot" | head -1)
    if [ -n "$name" ]; then
        echo "$name"
    else
        echo "finance-bot"
    fi
}

# ============================================================
# FUNGSI DASHBOARD & BINGKAI
# ============================================================

get_system_info() {
    OS=$(lsb_release -ds 2>/dev/null || echo "Ubuntu 22.04")
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "tidak diketahui")
    
    CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
    if [ -z "$CPU_USAGE" ] || [ "$CPU_USAGE" = "0" ]; then
        CPU_USAGE=$(top -bn1 2>/dev/null | grep "%Cpu" | awk '{print $2}' || echo "0")
    fi
    CPU_CORES=$(nproc 2>/dev/null || echo "1")
    
    MEM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "0")
    MEM_USED=$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo "0")
    if [ "$MEM_TOTAL" -gt 0 ]; then
        MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    else
        MEM_PERCENT=0
    fi
    
    DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
    DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "0")
    DISK_PERCENT=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    
    if systemctl is-active --quiet docker 2>/dev/null; then
        DOCKER_STATUS="BERJALAN"
        DOCKER_COLOR=$GREEN
    else
        DOCKER_STATUS="TERHENTI"
        DOCKER_COLOR=$RED
    fi
    
    BOT_STATUS="OFFLINE"
    BOT_COLOR=$RED
    BOT_UPTIME="N/A"
    BOT_RESTARTS="N/A"
    BOT_HEALTH="N/A"
    
    if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        BOT_STATUS="ONLINE"
        BOT_COLOR=$GREEN
        BOT_UPTIME=$(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME" 2>/dev/null | sed 's/Up //' | sed 's/ (healthy)//' | sed 's/ (unhealthy)//' || echo "N/A")
        BOT_RESTARTS=$(docker inspect --format='{{.RestartCount}}' "$CONTAINER_NAME" 2>/dev/null || echo "0")
        
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$HEALTH" = "healthy" ]; then
            BOT_HEALTH="SEHAT"
        elif [ "$HEALTH" = "unhealthy" ]; then
            BOT_HEALTH="TIDAK SEHAT"
        elif [ -n "$HEALTH" ]; then
            BOT_HEALTH="$HEALTH"
        else
            BOT_HEALTH="N/A"
        fi
    fi
}

get_color_for_percent() {
    local val=$1
    if [ -z "$val" ] || [ "$val" -lt 50 ]; then
        echo "$GREEN"
    elif [ "$val" -lt 80 ]; then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}

get_clean_length() {
    local text="$1"
    local clean=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    echo ${#clean}
}

print_box_line() {
    local text="$1"
    local clean_len=$(get_clean_length "$text")
    local pad=$((INNER_W - clean_len))
    [ $pad -lt 0 ] && pad=0
    printf "${CYAN}|${NC} %b%*s ${CYAN}|${NC}\n" "$text" $pad ""
}

print_box_line_color() {
    local text="$1"
    local color="${2:-$WHITE}"
    local full_text="${color}${text}${NC}"
    print_box_line "$full_text"
}

print_box_border() {
    local line="+"
    for ((i=0; i<INNER_W+2; i++)); do
        line="${line}-"
    done
    line="${line}+"
    echo -e "${CYAN}${line}${NC}"
}

draw_dashboard() {
    clear
    get_system_info
    
    echo ""
    print_box_border
    print_box_line_color "      SERVER BOT KEUANGAN" "$WHITE"
    print_box_border
    
    # Server Info
    print_box_line_color "SERVER      : $OS" "$WHITE"
    print_box_line_color "HOSTNAME    : $HOSTNAME" "$WHITE"
    print_box_line_color "WAKTU AKTIF : $UPTIME" "$WHITE"
    
    cpu_color=$(get_color_for_percent ${CPU_USAGE%.*})
    print_box_line "CPU         : ${cpu_color}${CPU_USAGE}% (${CPU_CORES} inti)${NC}"
    
    ram_color=$(get_color_for_percent $MEM_PERCENT)
    print_box_line "RAM         : ${ram_color}${MEM_USED}/${MEM_TOTAL} MB (${MEM_PERCENT}%)${NC}"
    
    disk_color=$(get_color_for_percent $DISK_PERCENT)
    print_box_line "PENYIMPANAN : ${disk_color}${DISK_USED}/${DISK_TOTAL} (${DISK_PERCENT}%)${NC}"
    
    print_box_line "DOCKER      : ${DOCKER_COLOR}${DOCKER_STATUS}${NC}"
    print_box_line "BOT KEUANGAN: ${BOT_COLOR}${BOT_STATUS}${NC}"
    
    if [ "$BOT_STATUS" = "ONLINE" ]; then
        print_box_line "  WAKTU AKTIF: ${GREEN}${BOT_UPTIME}${NC}"
        print_box_line "  RESTART    : ${WHITE}${BOT_RESTARTS}${NC}"
        if [ "$BOT_HEALTH" = "SEHAT" ]; then
            print_box_line "  KESEHATAN  : ${GREEN}SEHAT${NC}"
        elif [ "$BOT_HEALTH" = "TIDAK SEHAT" ]; then
            print_box_line "  KESEHATAN  : ${RED}TIDAK SEHAT${NC}"
        else
            print_box_line "  KESEHATAN  : ${YELLOW}${BOT_HEALTH}${NC}"
        fi
    fi
    
    print_box_border
    
    # Bottom Info
    print_box_line_color "AUTO REBOOT : 04:00" "$WHITE"
    print_box_line_color "WAKTU SERVER: $(date '+%H:%M:%S %Z' 2>/dev/null || date '+%H:%M:%S')" "$WHITE"
    print_box_line_color "TANGGAL     : $(date '+%A, %d %B %Y' 2>/dev/null || date '+%Y-%m-%d')" "$WHITE"
    
    print_box_border
    echo ""
}

# ============================================================
# MENU KONTROL
# ============================================================

show_menu() {
    print_box_border
    print_box_line_color "      KONTROL BOT KEUANGAN" "$WHITE"
    print_box_border
    print_box_line_color "  [1]  JALANKAN BOT" "$GREEN"
    print_box_line_color "  [2]  HENTIKAN BOT" "$RED"
    print_box_line_color "  [3]  RESTART BOT" "$YELLOW"
    print_box_line_color "  [4]  REBUILD & JALANKAN BOT" "$YELLOW"
    print_box_line_color "  [5]  STATUS BOT" "$BLUE"
    print_box_line_color "  [6]  LIHAT LOG" "$BLUE"
    print_box_line_color "  [7]  STATUS SISTEM" "$BLUE"
    print_box_line_color "  [8]  REFRESH DASHBOARD" "$BLUE"
    print_box_line_color "  [9]  REBOOT VPS" "$RED"
    print_box_line_color "  [10] UBAH BOT MANUAL (DIR PROYEK)" "$YELLOW"
    print_box_line_color "  [0]  KELUAR" "$RED"
    print_box_border
    echo ""
    echo -ne "${WHITE}Pilih opsi [0-10]: ${NC}"
}

# ============================================================
# FUNGSI MENU
# ============================================================

start_bot() {
    echo ""
    echo -e "${YELLOW}Menjalankan Bot Keuangan...${NC}"
    cd "$PROJECT_DIR" 2>/dev/null || { echo -e "${RED}Error: Direktori proyek tidak ditemukan${NC}"; return 1; }
    docker compose up -d 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bot Keuangan berhasil dijalankan${NC}"
        sleep 2
        show_bot_status
    else
        echo -e "${RED}❌ Gagal menjalankan Bot Keuangan${NC}"
    fi
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

stop_bot() {
    echo ""
    echo -e "${YELLOW}Menghentikan Bot Keuangan...${NC}"
    cd "$PROJECT_DIR" 2>/dev/null || { echo -e "${RED}Error: Direktori proyek tidak ditemukan${NC}"; return 1; }
    docker compose down 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bot Keuangan berhasil dihentikan${NC}"
    else
        echo -e "${RED}❌ Gagal menghentikan Bot Keuangan${NC}"
    fi
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

restart_bot() {
    echo ""
    echo -e "${YELLOW}Merestart Bot Keuangan...${NC}"
    cd "$PROJECT_DIR" 2>/dev/null || { echo -e "${RED}Error: Direktori proyek tidak ditemukan${NC}"; return 1; }
    docker compose restart 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bot Keuangan berhasil direstart${NC}"
        sleep 2
        show_bot_status
    else
        echo -e "${RED}❌ Gagal merestart Bot Keuangan${NC}"
    fi
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

rebuild_bot() {
    echo ""
    echo -e "${YELLOW}${BOLD}PERINGATAN: Rebuild memakan waktu dan menggunakan signifikan CPU/RAM${NC}"
    echo -ne "${WHITE}Lanjutkan? [y/N]: ${NC}"
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Rebuild dibatalkan.${NC}"
        echo ""
        echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
        read
        return
    fi
    echo ""
    echo -e "${YELLOW}Membangun ulang (Rebuild) Bot Keuangan...${NC}"
    echo -e "${YELLOW}Proses ini memerlukan waktu 2-5 menit...${NC}"
    cd "$PROJECT_DIR" 2>/dev/null || { echo -e "${RED}Error: Direktori proyek tidak ditemukan${NC}"; return 1; }
    echo -e "${BLUE}→ Membangun image...${NC}"
    docker compose build --no-cache 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Proses build gagal${NC}"
        echo ""
        echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
        read
        return
    fi
    echo -e "${BLUE}→ Menjalankan container...${NC}"
    docker compose up -d 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bot Keuangan berhasil dibangun ulang dan dijalankan${NC}"
        echo ""
        echo -e "${BLUE}Log terbaru:${NC}"
        docker compose logs --tail=15 2>&1
    else
        echo -e "${RED}❌ Gagal menjalankan bot setelah rebuild${NC}"
    fi
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

show_bot_status() {
    echo ""
    echo -e "${BLUE}${BOLD}STATUS BOT KEUANGAN${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}Status: BERJALAN${NC}"
        echo -e "Container: ${WHITE}$CONTAINER_NAME${NC}"
        echo -e "Waktu Aktif: ${WHITE}$(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME" 2>/dev/null)${NC}"
        echo -e "Restart: ${WHITE}$(docker inspect --format='{{.RestartCount}}' "$CONTAINER_NAME" 2>/dev/null || echo "0")${NC}"
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$HEALTH" = "healthy" ]; then
            echo -e "Kesehatan: ${GREEN}SEHAT${NC}"
        elif [ "$HEALTH" = "unhealthy" ]; then
            echo -e "Kesehatan: ${RED}TIDAK SEHAT${NC}"
        else
            echo -e "Kesehatan: ${YELLOW}$HEALTH${NC}"
        fi
    else
        echo -e "${RED}Status: TERHENTI${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

view_logs() {
    echo ""
    echo -e "${BLUE}${BOLD}LOG BOT KEUANGAN (${LOG_LINES} baris terakhir)${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    cd "$PROJECT_DIR" 2>/dev/null || { echo -e "${RED}Error: Direktori proyek tidak ditemukan${NC}"; return 1; }
    docker compose logs --tail=$LOG_LINES 2>&1
    echo -e "${CYAN}----------------------------------------${NC}"
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

show_system_status() {
    echo ""
    echo -e "${BLUE}${BOLD}STATUS SISTEM${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    echo -e "${WHITE}OS:${NC} $(lsb_release -ds 2>/dev/null || echo "Tidak diketahui")"
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Waktu Aktif:${NC} $(uptime -p 2>/dev/null | sed 's/up //' || echo "tidak diketahui")"
    CPU=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
    NCORES=$(nproc 2>/dev/null || echo "1")
    echo -e "${WHITE}CPU:${NC} ${CPU}% (${NCORES} inti)"
    MEM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "N/A")
    MEM_USED=$(free -h 2>/dev/null | awk '/Mem:/ {print $3}' || echo "N/A")
    echo -e "${WHITE}RAM:${NC} ${MEM_USED}/${MEM_TOTAL}"
    DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "N/A")
    DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "N/A")
    echo -e "${WHITE}Penyimpanan:${NC} ${DISK_USED}/${DISK_TOTAL}"
    echo -e "${WHITE}Docker:${NC} $(docker --version 2>/dev/null | head -1 || echo "Tidak terinstall")"
    echo -e "${WHITE}Layanan Docker:${NC} $(systemctl is-active docker 2>/dev/null || echo "tidak diketahui")"
    echo -e "${WHITE}Bot Keuangan:${NC} "
    if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "  Status: ${GREEN}BERJALAN${NC}"
        echo -e "  Waktu Aktif: $(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME" 2>/dev/null)"
    else
        echo -e "  Status: ${RED}TERHENTI${NC}"
    fi
    if crontab -l 2>/dev/null | grep -q "reboot"; then
        echo -e "${WHITE}Auto Reboot:${NC} ${GREEN}AKTIF (04:00)${NC}"
    else
        echo -e "${WHITE}Auto Reboot:${NC} ${YELLOW}BELUM DIKONFIGURASI${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
    echo ""
    echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
    read
}

reboot_vps() {
    echo ""
    echo -e "${RED}${BOLD}PERINGATAN: Seluruh layanan di VPS akan terhenti sementara!${NC}"
    echo -ne "${WHITE}Apakah Anda yakin ingin merestart VPS? [y/N]: ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Merestart sistem VPS sekarang...${NC}"
        sudo reboot || reboot
    else
        echo -e "${YELLOW}Reboot VPS dibatalkan.${NC}"
        echo ""
        echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
        read
    fi
}

manual_edit_bot() {
    echo ""
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${GREEN}Pindah ke direktori: $PROJECT_DIR${NC}"
        echo -e "${YELLOW}Keluar dari dashboard... Anda sekarang berada di direktori proyek.${NC}"
        echo ""
        exec bash --rcfile <(echo "cd '$PROJECT_DIR'")
    else
        echo -e "${RED}Error: Direktori proyek $PROJECT_DIR tidak ditemukan!${NC}"
        echo ""
        echo -ne "${WHITE}Tekan Enter untuk melanjutkan...${NC}"
        read
    fi
}

# ============================================================
# MAIN LOOP
# ============================================================

main() {
    DETECTED_DIR=$(detect_project_dir)
    if [ -n "$DETECTED_DIR" ]; then
        PROJECT_DIR="$DETECTED_DIR"
    fi
    
    DETECTED_CONTAINER=$(detect_container_name)
    if [ -n "$DETECTED_CONTAINER" ]; then
        CONTAINER_NAME="$DETECTED_CONTAINER"
    fi
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}Error: Proyek Bot Keuangan tidak ditemukan di: $PROJECT_DIR${NC}"
        echo ""
        echo -ne "${WHITE}Tekan Enter untuk keluar...${NC}"
        read
        exit 1
    fi
    
    while true; do
        draw_dashboard
        show_menu
        read choice
        
        case $choice in
            1) start_bot ;;
            2) stop_bot ;;
            3) restart_bot ;;
            4) rebuild_bot ;;
            5) show_bot_status ;;
            6) view_logs ;;
            7) show_system_status ;;
            8) continue ;;
            9) reboot_vps ;;
            10) manual_edit_bot ;;
            0) 
                echo -e "${GREEN}Keluar dari Panel Kontrol Bot Keuangan...${NC}"
                echo ""
                exit 0
                ;;
            *) 
                echo -e "${RED}Opsi tidak valid. Silakan pilih 0-10${NC}"
                sleep 1
                ;;
        esac
    done
}

main
