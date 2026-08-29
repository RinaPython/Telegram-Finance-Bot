#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - DASHBOARD VPS v2.0
# ============================================================

set -Eeuo pipefail

# ============================================================
# KONFIGURASI
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# FUNGSI UTILITY
# ============================================================

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}🤖 SERVER BOT KEUANGAN${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# ============================================================
# INFORMASI SISTEM
# ============================================================

get_system_info() {
    local hostname=$(hostname)
    local uptime=$(uptime -p | sed 's/up //')
    local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1 || echo "0")
    local ram_total=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "0")
    local ram_used=$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo "0")
    local ram_percent=$((ram_used * 100 / ram_total))
    local disk_total=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
    local disk_used=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "0")
    local disk_percent=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "0%")
    local docker_status=$(systemctl is-active docker 2>/dev/null || echo "inactive")
    local docker_icon=$( [[ "$docker_status" == "active" ]] && echo -e "${GREEN}BERJALAN${NC}" || echo -e "${RED}BERHENTI${NC}" )
    
    local bot_status="OFFLINE"
    local bot_uptime="N/A"
    local bot_restart="N/A"
    local bot_health="TIDAK DIKETAHUI"
    
    if cd "$INSTALL_DIR" 2>/dev/null && docker compose ps 2>/dev/null | grep -q "finance-bot"; then
        local container_status=$(docker compose ps --format json 2>/dev/null | jq -r '.[0].State' 2>/dev/null || echo "exited")
        if [[ "$container_status" == "running" ]]; then
            bot_status="ONLINE"
            bot_uptime=$(docker inspect finance-bot 2>/dev/null | jq -r '.[0].State.StartedAt' 2>/dev/null | cut -d'T' -f1 || echo "N/A")
            bot_restart=$(docker inspect finance-bot 2>/dev/null | jq -r '.[0].RestartCount' 2>/dev/null || echo "0")
            local health=$(docker inspect finance-bot 2>/dev/null | jq -r '.[0].State.Health.Status' 2>/dev/null || echo "none")
            [[ "$health" == "healthy" ]] && bot_health="${GREEN}SEHAT${NC}"
            [[ "$health" == "unhealthy" ]] && bot_health="${RED}TIDAK SEHAT${NC}"
        fi
    fi
    
    echo -e "${CYAN}SERVER    :${NC} Ubuntu 22.04/24.04"
    echo -e "${CYAN}HOSTNAME  :${NC} $hostname"
    echo -e "${CYAN}WAKTU AKTIF :${NC} $uptime"
    echo -e "${CYAN}CPU       :${NC} ${cpu_usage}% (1 inti)"
    echo -e "${CYAN}RAM       :${NC} ${ram_used}/${ram_total} MB (${ram_percent}%)"
    echo -e "${CYAN}PENYIMPANAN :${NC} ${disk_used}/${disk_total} (${disk_percent})"
    echo -e "${CYAN}DOCKER    :${NC} $docker_icon"
    
    if [[ "$bot_status" == "ONLINE" ]]; then
        echo -e "${CYAN}BOT KEUANGAN :${NC} ${GREEN}ONLINE${NC}"
        echo -e "${CYAN}WAKTU AKTIF :${NC} $bot_uptime"
        echo -e "${CYAN}RESTART   :${NC} $bot_restart"
        echo -e "${CYAN}KESEHATAN  :${NC} $bot_health"
    else
        echo -e "${CYAN}BOT KEUANGAN :${NC} ${RED}OFFLINE${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}WAKTU SERVER :${NC} $(date '+%H:%M:%S %Z')"
    echo -e "${CYAN}TANGGAL      :${NC} $(date '+%A, %d %B %Y')"
}

# ============================================================
# KONTROL BOT
# ============================================================

start_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}JALANKAN BOT${NC}"
    print_info "Memulai bot keuangan..."
    cd "$INSTALL_DIR"
    if docker compose up -d; then
        print_success "Bot berhasil dijalankan"
    else
        print_error "Gagal menjalankan bot"
    fi
    sleep 2
}

stop_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}HENTIKAN BOT${NC}"
    print_info "Menghentikan bot keuangan..."
    cd "$INSTALL_DIR"
    if docker compose down; then
        print_success "Bot berhasil dihentikan"
    else
        print_error "Gagal menghentikan bot"
    fi
    sleep 2
}

restart_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}RESTART BOT${NC}"
    print_info "Merestart bot keuangan..."
    cd "$INSTALL_DIR"
    if docker compose restart; then
        print_success "Bot berhasil direstart"
    else
        print_error "Gagal merestart bot"
    fi
    sleep 2
}

rebuild_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}REBUILD & JALANKAN BOT${NC}"
    print_info "Membangun ulang image dan menjalankan bot..."
    cd "$INSTALL_DIR"
    print_info "Mengambil update dari GitHub..."
    git pull 2>/dev/null || true
    print_info "Membangun ulang image..."
    if docker compose build --no-cache; then
        print_success "Image berhasil dibangun"
        print_info "Menjalankan container..."
        if docker compose up -d; then
            print_success "Bot berhasil dijalankan"
        else
            print_error "Gagal menjalankan bot"
        fi
    else
        print_error "Gagal membangun image"
    fi
    sleep 2
}

show_status() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}STATUS BOT${NC}"
    cd "$INSTALL_DIR" 2>/dev/null || {
        print_error "Direktori instalasi tidak ditemukan"
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
        return
    }
    
    if docker compose ps 2>/dev/null; then
        echo ""
        echo -e "${CYAN}📊 INFORMASI DETAIL:${NC}"
        docker inspect finance-bot 2>/dev/null | jq -r '.[0] | {
            Name: .Name,
            Status: .State.Status,
            Health: .State.Health.Status,
            Restarts: .RestartCount,
            Started: .State.StartedAt,
            Image: .Image
        }' 2>/dev/null || echo "  Tidak dapat mengambil detail container"
    else
        print_error "Bot tidak berjalan atau tidak ditemukan"
    fi
    
    echo ""
    echo "Tekan Enter untuk kembali..."
    read
}

show_logs() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}LIHAT LOG${NC}"
    cd "$INSTALL_DIR" 2>/dev/null || {
        print_error "Direktori instalasi tidak ditemukan"
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
        return
    }
    
    echo -e "${CYAN}📋 LOG 50 BARIS TERAKHIR:${NC}"
    echo ""
    docker compose logs --tail=50 2>/dev/null || print_error "Tidak ada log tersedia"
    echo ""
    echo -e "${YELLOW}Tips: Untuk melihat log real-time, jalankan:${NC}"
    echo "  cd $INSTALL_DIR && docker compose logs -f"
    echo ""
    echo "Tekan Enter untuk kembali..."
    read
}

show_system_status() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}STATUS SISTEM${NC}"
    
    echo -e "${CYAN}🔍 STATUS LAYANAN:${NC}"
    echo ""
    
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✓${NC} Docker: ${GREEN}BERJALAN${NC}"
    else
        echo -e "${RED}✗${NC} Docker: ${RED}BERHENTI${NC}"
    fi
    
    cd "$INSTALL_DIR" 2>/dev/null
    if docker compose ps 2>/dev/null | grep -q "finance-bot"; then
        echo -e "${GREEN}✓${NC} Container Bot: ${GREEN}BERJALAN${NC}"
    else
        echo -e "${RED}✗${NC} Container Bot: ${RED}TIDAK BERJALAN${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}💾 PENGGUNAAN DISK:${NC}"
    df -h | grep -E "(Filesystem|/dev/root|/dev/vd|/dev/sd|mapper)" | grep -v "snap"
    
    echo ""
    echo -e "${CYAN}🧠 PENGGUNAAN MEMORI:${NC}"
    free -h
    
    echo ""
    echo "Tekan Enter untuk kembali..."
    read
}

update_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}UPDATE DARI GITHUB${NC}"
    print_info "Mengupdate bot ke versi terbaru..."
    cd "$INSTALL_DIR"
    
    print_info "Menyimpan file .env..."
    if [[ -f .env ]]; then
        cp .env .env.backup
        print_success "File .env dicadangkan"
    fi
    
    print_info "Mengambil perubahan dari GitHub..."
    if git pull; then
        print_success "Update berhasil diambil"
        print_info "Membangun ulang image..."
        if docker compose build --no-cache; then
            print_success "Image berhasil dibangun"
            print_info "Menjalankan ulang bot..."
            if docker compose up -d; then
                print_success "Bot berhasil diperbarui dan dijalankan"
            else
                print_error "Gagal menjalankan bot"
            fi
        else
            print_error "Gagal membangun image"
        fi
    else
        print_error "Gagal mengambil update dari GitHub"
        if [[ -f .env.backup ]]; then
            mv .env.backup .env
            print_info "File .env dikembalikan"
        fi
    fi
    
    sleep 2
}

reboot_vps() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}REBOOT VPS${NC}"
    echo -e "${RED}⚠️  PERINGATAN: VPS akan di-reboot!${NC}"
    echo ""
    echo -e "${YELLOW}Bot akan otomatis berjalan setelah reboot.${NC}"
    echo ""
    echo -n "Apakah Anda yakin? (ketik 'y' untuk lanjut): "
    read confirm
    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        print_info "Merestart VPS dalam 5 detik..."
        sleep 5
        sudo reboot
    else
        print_info "Reboot dibatalkan"
        sleep 2
    fi
}

# ============================================================
# MENU UTAMA
# ============================================================

show_menu() {
    print_header
    get_system_info
    echo ""
    echo -e "${BLUE}---${NC} ${BOLD}KONTROL BOT KEUANGAN${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} JALANKAN BOT"
    echo -e "${CYAN}[2]${NC} HENTIKAN BOT"
    echo -e "${CYAN}[3]${NC} RESTART BOT"
    echo -e "${CYAN}[4]${NC} REBUILD & JALANKAN BOT"
    echo -e "${CYAN}[5]${NC} STATUS BOT"
    echo -e "${CYAN}[6]${NC} LIHAT LOG"
    echo -e "${CYAN}[7]${NC} STATUS SISTEM"
    echo -e "${CYAN}[8]${NC} REFRESH DASHBOARD"
    echo -e "${CYAN}[9]${NC} REBOOT VPS"
    echo -e "${CYAN}[10]${NC} UPDATE DARI GITHUB"
    echo -e "${CYAN}[0]${NC} KELUAR"
    echo ""
    echo -n "Pilih opsi [0-10]: "
    read choice
    echo ""
    
    case $choice in
        1) start_bot ;;
        2) stop_bot ;;
        3) restart_bot ;;
        4) rebuild_bot ;;
        5) show_status ;;
        6) show_logs ;;
        7) show_system_status ;;
        8) return ;;
        9) reboot_vps ;;
        10) update_bot ;;
        0) 
            echo -e "${GREEN}Terima kasih! Sampai jumpa.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opsi tidak valid${NC}"
            sleep 1
            ;;
    esac
}

# ============================================================
# MAIN LOOP
# ============================================================

main() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}Error: Direktori instalasi tidak ditemukan: $INSTALL_DIR${NC}"
        echo "Pastikan bot sudah diinstall terlebih dahulu."
        exit 1
    fi
    
    while true; do
        show_menu
    done
}

trap 'echo ""; echo -e "${GREEN}Terima kasih! Sampai jumpa.${NC}"; exit 0' INT

main
