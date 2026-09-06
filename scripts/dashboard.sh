#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - DASHBOARD VPS v4.2
# ============================================================
# Menu kontrol bot - START & RESTART wajib validasi
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
SCRIPT_DIR="$INSTALL_DIR/scripts"

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
# INSTALL MODE
# ============================================================
if [[ "${1:-}" == "install" ]]; then
    DASHBOARD_TARGET="/usr/local/bin/finance-dashboard"
    if [[ -f "$INSTALL_DIR/scripts/dashboard.sh" ]]; then
        cp "$INSTALL_DIR/scripts/dashboard.sh" "$DASHBOARD_TARGET"
        chmod 755 "$DASHBOARD_TARGET"
        echo -e "${GREEN}✅ Dashboard terinstall. Jalankan dengan: finance-dashboard${NC}"
    fi
    exit 0
fi

# ============================================================
# FUNGSI UTILITY
# ============================================================
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${WHITE}${BOLD}🤖 FINANCE BOT SERVER${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }

# ============================================================
# VALIDASI DEPENDENCY
# ============================================================
if ! command -v jq &> /dev/null; then
    print_error "jq tidak ditemukan. Dashboard membutuhkan jq."
    print_info "Install: apt-get install jq -y"
    exit 1
fi

# ============================================================
# SISTEM INFO
# ============================================================
get_system_info() {
    local hostname=$(hostname)
    local uptime=$(uptime -p | sed 's/up //')
    local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1 || echo "0")
    local ram_total=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "0")
    local ram_used=$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo "0")
    local ram_percent=0
    [[ $ram_total -gt 0 ]] && ram_percent=$((ram_used * 100 / ram_total))
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
            [[ "$health" == "none" || "$health" == "" ]] && bot_health="${YELLOW}TIDAK DIKONFIGURASI${NC}"
        fi
    fi
    
    echo -e "${CYAN}SERVER    :${NC} Ubuntu"
    echo -e "${CYAN}HOSTNAME  :${NC} $hostname"
    echo -e "${CYAN}WAKTU AKTIF :${NC} $uptime"
    echo -e "${CYAN}CPU       :${NC} ${cpu_usage}%"
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
# FUNGSI KONTROL
# ============================================================

# --- START BOT (WAJIB VALIDASI) ---
start_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}JALANKAN BOT${NC}"
    echo ""
    
    # 1. Validasi Konfigurasi - WAJIB
    print_info "Memeriksa validasi konfigurasi..."
    if [[ ! -f "$SCRIPT_DIR/validate-config.sh" ]]; then
        print_error "Script validate-config.sh tidak ditemukan."
        sleep 2
        return
    fi
    
    if bash "$SCRIPT_DIR/validate-config.sh" "silent"; then
        print_success "Konfigurasi VALID."
    else
        print_warning "Konfigurasi TIDAK VALID. Bot TIDAK dapat dijalankan."
        echo ""
        print_info "Langkah selanjutnya:"
        echo "  1. Perbaiki file .env: nano $INSTALL_DIR/.env"
        echo "  2. Jalankan installer ulang: sudo bash $INSTALL_DIR/install.sh"
        echo ""
        print_info "Tekan Enter untuk kembali ke menu..."
        read
        return
    fi
    
    # 2. Pastikan di direktori yang benar
    cd "$INSTALL_DIR" || {
        print_error "Direktori tidak ditemukan: $INSTALL_DIR"
        sleep 2
        return
    }
    
    # 3. Cek apakah container sudah running
    if docker compose ps 2>/dev/null | grep -q "Up"; then
        print_warning "Bot sudah berjalan."
        sleep 2
        return
    fi
    
    # 4. Start bot
    print_info "Menjalankan bot..."
    if docker compose up -d; then
        print_success "Bot berhasil dijalankan."
        sleep 2
    else
        print_error "Gagal menjalankan bot."
        echo ""
        print_info "Log error:"
        docker compose logs --tail=20
        echo ""
        print_info "Tekan Enter untuk kembali..."
        read
    fi
}

# --- STOP BOT ---
stop_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}HENTIKAN BOT${NC}"
    echo ""
    
    cd "$INSTALL_DIR" || {
        print_error "Direktori tidak ditemukan: $INSTALL_DIR"
        sleep 2
        return
    }
    
    if docker compose ps 2>/dev/null | grep -q "Up"; then
        print_info "Menghentikan bot..."
        if docker compose down; then
            print_success "Bot berhasil dihentikan."
        else
            print_error "Gagal menghentikan bot."
        fi
    else
        print_warning "Bot tidak sedang berjalan."
    fi
    sleep 2
}

# --- RESTART BOT (WAJIB VALIDASI) ---
restart_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}RESTART BOT${NC}"
    echo ""
    
    cd "$INSTALL_DIR" || {
        print_error "Direktori tidak ditemukan: $INSTALL_DIR"
        sleep 2
        return
    }
    
    # Validasi config - WAJIB
    print_info "Memeriksa validasi konfigurasi..."
    if [[ ! -f "$SCRIPT_DIR/validate-config.sh" ]]; then
        print_error "Script validate-config.sh tidak ditemukan."
        sleep 2
        return
    fi
    
    if ! bash "$SCRIPT_DIR/validate-config.sh" "silent"; then
        print_warning "Konfigurasi TIDAK VALID. Bot TIDAK dapat direstart."
        echo ""
        print_info "Perbaiki .env dan coba lagi."
        sleep 3
        return
    fi
    
    print_info "Merestart bot..."
    if docker compose restart; then
        print_success "Bot berhasil direstart."
    else
        print_error "Gagal merestart bot."
        echo ""
        print_info "Log error:"
        docker compose logs --tail=20
    fi
    sleep 2
}

# --- STATUS BOT ---
show_status() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}STATUS BOT${NC}"
    echo ""
    
    cd "$INSTALL_DIR" 2>/dev/null || {
        print_error "Direktori instalasi tidak ditemukan: $INSTALL_DIR"
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
        print_error "Bot tidak berjalan atau tidak ditemukan."
    fi
    
    echo ""
    echo "Tekan Enter untuk kembali..."
    read
}

# --- LOGS ---
show_logs() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}LIHAT LOG${NC}"
    echo ""
    
    cd "$INSTALL_DIR" 2>/dev/null || {
        print_error "Direktori instalasi tidak ditemukan: $INSTALL_DIR"
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
        return
    }
    
    echo -e "${CYAN}📋 LOG 50 BARIS TERAKHIR:${NC}"
    echo ""
    docker compose logs --tail=50 2>/dev/null || print_error "Tidak ada log tersedia"
    echo ""
    echo -e "${YELLOW}Tips: Untuk melihat log real-time:${NC}"
    echo "  docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
    echo ""
    echo "Tekan Enter untuk kembali..."
    read
}

# --- SYSTEM STATUS ---
show_system_status() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}STATUS SISTEM${NC}"
    echo ""
    
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

# --- UPDATE ---
update_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}UPDATE BOT${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/update.sh" ]]; then
        bash "$INSTALL_DIR/update.sh"
    else
        print_error "Script update.sh tidak ditemukan di $INSTALL_DIR"
        echo ""
        print_info "Pastikan update.sh ada di direktori instalasi."
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
    fi
}

# --- BACKUP ---
backup_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}BACKUP BOT${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/backup.sh" ]]; then
        bash "$INSTALL_DIR/backup.sh"
    else
        print_error "Script backup.sh tidak ditemukan di $INSTALL_DIR"
        echo ""
        print_info "Pastikan backup.sh ada di direktori instalasi."
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
    fi
}

# --- UNINSTALL ---
uninstall_bot() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}UNINSTALL BOT${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/uninstall.sh" ]]; then
        bash "$INSTALL_DIR/uninstall.sh"
    else
        print_error "Script uninstall.sh tidak ditemukan di $INSTALL_DIR"
        echo ""
        print_info "Pastikan uninstall.sh ada di direktori instalasi."
        echo ""
        echo "Tekan Enter untuk kembali..."
        read
    fi
}

# --- REBOOT VPS ---
reboot_vps() {
    print_header
    echo -e "${BLUE}---${NC} ${BOLD}REBOOT VPS${NC}"
    echo ""
    echo -e "${RED}⚠️  PERINGATAN: VPS akan di-reboot!${NC}"
    echo ""
    echo -e "${YELLOW}Bot akan otomatis berjalan setelah reboot (restart: unless-stopped).${NC}"
    echo ""
    echo -n "Apakah Anda yakin? (ketik 'y' untuk lanjut): "
    read -r confirm
    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        print_info "Merestart VPS dalam 5 detik..."
        sleep 5
        sudo reboot
    else
        print_info "Reboot dibatalkan."
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
    echo -e "${CYAN}[1]${NC} JALANKAN BOT ${YELLOW}(dengan validasi)${NC}"
    echo -e "${CYAN}[2]${NC} HENTIKAN BOT"
    echo -e "${CYAN}[3]${NC} RESTART BOT ${YELLOW}(dengan validasi)${NC}"
    echo -e "${CYAN}[4]${NC} STATUS BOT"
    echo -e "${CYAN}[5]${NC} LIHAT LOG"
    echo -e "${CYAN}[6]${NC} STATUS SISTEM"
    echo -e "${CYAN}[7]${NC} REFRESH DASHBOARD"
    echo -e "${CYAN}[8]${NC} UPDATE BOT"
    echo -e "${CYAN}[9]${NC} BACKUP BOT"
    echo -e "${CYAN}[10]${NC} UNINSTALL BOT"
    echo -e "${CYAN}[11]${NC} REBOOT VPS"
    echo -e "${CYAN}[0]${NC} KELUAR"
    echo ""
    echo -n "Pilih opsi [0-11]: "
    read -r choice
    echo ""
    
    case $choice in
        1) start_bot ;;
        2) stop_bot ;;
        3) restart_bot ;;
        4) show_status ;;
        5) show_logs ;;
        6) show_system_status ;;
        7) return ;;
        8) update_bot ;;
        9) backup_bot ;;
        10) uninstall_bot ;;
        11) reboot_vps ;;
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
# MAIN
# ============================================================
main() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}Error: Direktori instalasi tidak ditemukan: $INSTALL_DIR${NC}"
        echo "Pastikan bot sudah diinstall terlebih dahulu."
        echo ""
        echo "Jalankan installer:"
        echo "  curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/install.sh | sudo bash"
        exit 1
    fi
    
    while true; do
        show_menu
    done
}

trap 'echo ""; echo -e "${GREEN}Terima kasih! Sampai jumpa.${NC}"; exit 0' INT TERM

main