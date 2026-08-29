#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - BOOTSTRAP INSTALLER v2.0
# ============================================================
# Penggunaan:
#   curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/scripts/bootstrap.sh | sudo bash
# ============================================================

set -Eeuo pipefail

# ============================================================
# KONFIGURASI
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
REPO_URL="https://github.com/RinaPython/Telegram-Finance-Bot.git"
REQUIRED_ENV_VARS=("TELEGRAM_TOKEN" "AUTHORIZED_USER_ID" "GEMINI_API_KEY")

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# FUNGSI UTILITY
# ============================================================

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# CEK PRASYARAT
# ============================================================

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini HARUS dijalankan dengan sudo atau sebagai root."
        echo "Gunakan: curl -fsSL <url> | sudo bash"
        exit 1
    fi
    print_success "Hak akses root/sudo terkonfirmasi"
}

check_internet() {
    print_info "Memeriksa koneksi internet..."
    
    local test_urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://api.github.com"
        "https://www.google.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -4 -sSf --connect-timeout 5 --max-time 10 -o /dev/null "$url" 2>/dev/null; then
            print_success "Koneksi internet: OK (${url})"
            return 0
        fi
    done
    
    print_error "Koneksi internet: GAGAL"
    echo ""
    echo "[DIAGNOSTIK] Semua endpoint gagal dijangkau. Periksa:"
    echo "  1. DNS: apakah 'getent hosts github.com' berhasil?"
    echo "  2. Firewall: apakah blokir port 443 (HTTPS)?"
    echo "  3. Proxy: jika ada, atur environment variable http_proxy."
    exit 1
}

check_os() {
    print_info "Memeriksa sistem operasi..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Sistem operasi: Ubuntu $VERSION_ID"
        else
            print_error "Sistem operasi tidak didukung. Hanya Ubuntu yang didukung."
            echo "OS terdeteksi: $ID $VERSION_ID"
            exit 1
        fi
    else
        print_error "Tidak dapat mendeteksi sistem operasi."
        exit 1
    fi
}

# ============================================================
# FUNGSI REPOSITORY
# ============================================================

clone_or_update_repository() {
    print_info "Mempersiapkan repository..."
    
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        print_success "Repository sudah ada di $INSTALL_DIR"
        print_info "Memperbarui repository..."
        cd "$INSTALL_DIR"
        git pull --ff-only 2>/dev/null || print_warning "Tidak dapat pull update, melanjutkan..."
        return 0
    fi
    
    print_info "Meng-clone repository ke $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
    print_success "Repository berhasil di-clone"
}

# ============================================================
# VALIDASI .env (BERDASARKAN SOURCE CODE)
# ============================================================

validate_env() {
    local env_file="$INSTALL_DIR/.env"
    local missing=()
    local valid=true
    
    if [[ ! -f "$env_file" ]]; then
        print_warning "File .env belum dibuat"
        return 1
    fi
    
    # Source file .env
    set -a
    # shellcheck source=/dev/null
    source "$env_file"
    set +a
    
    print_info "Memvalidasi file .env (berdasarkan source code)..."
    
    # Cek 3 variable WAJIB dari src/config/settings.py
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
            valid=false
        fi
    done
    
    if [[ "$valid" == false ]]; then
        print_warning "Konfigurasi .env BELUM LENGKAP"
        echo ""
        echo "  Variabel WAJIB yang hilang:"
        for m in "${missing[@]}"; do
            echo -e "    ${RED}✗${NC} $m"
        done
        echo ""
        echo "  Variabel OPSIONAL (tidak wajib, bot tetap jalan):"
        echo "    - SPREADSHEET_ID (untuk Google Sheets)"
        echo "    - GOOGLE_SHEETS_CREDENTIALS_JSON (untuk Google Sheets)"
        echo "    - DELETE_MESSAGES (default: true)"
        echo "    - HISTORY_PAGE_SIZE (default: 5)"
        echo "    - TZ (default: Asia/Jakarta)"
        echo "    - LOG_LEVEL (default: INFO)"
        echo ""
        return 1
    fi
    
    # Validasi format TELEGRAM_TOKEN
    if [[ -n "${TELEGRAM_TOKEN:-}" ]] && [[ ! "${TELEGRAM_TOKEN:-}" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        print_warning "Format TELEGRAM_TOKEN tidak valid (harus seperti: 123456:ABCdef...)"
        return 1
    fi
    
    # Validasi AUTHORIZED_USER_ID adalah angka
    if [[ -n "${AUTHORIZED_USER_ID:-}" ]] && [[ ! "${AUTHORIZED_USER_ID:-}" =~ ^[0-9]+$ ]]; then
        print_warning "Format AUTHORIZED_USER_ID tidak valid (harus berupa angka)"
        return 1
    fi
    
    print_success "✅ Semua konfigurasi .env LENGKAP dan VALID"
    echo ""
    print_info "Variable yang terdeteksi:"
    echo "  - TELEGRAM_TOKEN: [TERSET]"
    echo "  - AUTHORIZED_USER_ID: [TERSET]"
    echo "  - GEMINI_API_KEY: [TERSET]"
    [[ -n "${SPREADSHEET_ID:-}" ]] && echo "  - SPREADSHEET_ID: [TERSET] (opsional)"
    [[ -n "${GOOGLE_SHEETS_CREDENTIALS_JSON:-}" ]] && echo "  - GOOGLE_SHEETS_CREDENTIALS_JSON: [TERSET] (opsional)"
    echo ""
    return 0
}

# ============================================================
# INSTALASI VPS
# ============================================================

install_vps() {
    local install_script="$INSTALL_DIR/scripts/install-vps.sh"
    
    if [[ ! -f "$install_script" ]]; then
        print_error "File install-vps.sh tidak ditemukan di $install_script"
        exit 1
    fi
    
    print_info "Menjalankan install-vps.sh..."
    if bash "$install_script"; then
        print_success "Instalasi VPS selesai"
        return 0
    else
        print_error "Instalasi VPS gagal"
        exit 1
    fi
}

# ============================================================
# START BOT (HANYA JIKA .env LENGKAP)
# ============================================================

start_bot() {
    print_info "Menjalankan Finance Bot..."
    cd "$INSTALL_DIR"
    
    # Pastikan restart policy ada
    if ! grep -q "restart:" "$INSTALL_DIR/docker-compose.yml" 2>/dev/null; then
        print_info "Menambahkan restart policy ke docker-compose.yml..."
        sed -i '/^services:/,/^[^ ]/ { /finance-bot:/,/^[^ ]/ s/\(^[[:space:]]*\)container_name:/\1restart: unless-stopped\n\1container_name:/ }' "$INSTALL_DIR/docker-compose.yml"
    fi
    
    if docker compose up -d; then
        print_success "✅ Finance Bot berhasil dijalankan"
        return 0
    else
        print_error "Gagal menjalankan Finance Bot"
        return 1
    fi
}

# ============================================================
# REBOOT (OPSIONAL, TIDAK PAKSA)
# ============================================================

ask_reboot() {
    echo ""
    echo -n "Apakah ingin merestart VPS sekarang? (y/n): "
    read -r confirm
    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        print_info "Merestart VPS dalam 5 detik..."
        sleep 5
        sudo reboot
    else
        print_info "Reboot ditunda. Anda dapat reboot nanti dengan: sudo reboot"
    fi
}

# ============================================================
# FUNGSI UTAMA
# ============================================================

main() {
    clear
    print_header "🚀 TELEGRAM FINANCE BOT - INSTALASI OTOMATIS v2.0"
    echo ""
    
    # Prasyarat
    check_sudo
    check_internet
    check_os
    
    echo ""
    # Repository
    clone_or_update_repository
    
    echo ""
    # Install VPS (Docker, Dashboard, .env)
    install_vps
    
    echo ""
    print_header "📋 VALIDASI KONFIGURASI"
    
    # Validasi .env
    if validate_env; then
        # .env LENGKAP - Build & Start Bot
        echo ""
        start_bot
        
        echo ""
        print_info "Menjalankan health check..."
        if bash "$INSTALL_DIR/scripts/health-check.sh" 2>/dev/null; then
            print_success "✅ Health check: SEMUA SISTEM SEHAT"
        else
            print_warning "Health check: beberapa komponen bermasalah, periksa log"
        fi
        
        echo ""
        print_header "✅ INSTALASI LENGKAP - BOT AKTIF"
        echo ""
        echo "Finance Dashboard: ✅ TERINSTALL & AKTIF"
        echo "Finance Bot:       ✅ BERJALAN"
        echo "Restart Policy:    ✅ unless-stopped"
        echo ""
        
        ask_reboot
        
    else
        # .env BELUM LENGKAP - Dashboard Only
        echo ""
        echo -e "${GREEN}✅ Finance Dashboard: TERINSTALL & AKTIF${NC}"
        echo -e "${YELLOW}⏸️  Finance Bot: MENUNGGU KONFIGURASI .env${NC}"
        echo ""
        print_warning "Finance Bot TIDAK dijalankan karena konfigurasi belum lengkap."
        echo ""
        print_info "Langkah selanjutnya:"
        echo "  1. Isi file .env: nano $INSTALL_DIR/.env"
        echo "  2. Variabel WAJIB yang harus diisi:"
        for var in "${REQUIRED_ENV_VARS[@]}"; do
            echo "     - $var"
        done
        echo "  3. Jalankan ulang installer setelah .env diisi:"
        echo "     sudo bash $INSTALL_DIR/scripts/bootstrap.sh"
        echo "  4. Atau jalankan dashboard: finance-dashboard"
        echo ""
        print_header "✅ INSTALASI SELESAI - MODE DASHBOARD SAJA"
        echo ""
        echo "Dashboard: finance-dashboard"
        echo "Direktori: $INSTALL_DIR"
        echo ""
    fi
}

# ============================================================
# EKSEKUSI
# ============================================================

main
