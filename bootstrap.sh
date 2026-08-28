#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - BOOTSTRAP INSTALLER v2.0
# ============================================================
# Penggunaan:
#   curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/scripts/bootstrap.sh | sudo bash
# ============================================================

set -Eeuo pipefail

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/Telegram-Finance-Bot"

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
    echo "Diagnostik: Periksa DNS, Firewall (port 443), atau Proxy."
    exit 1
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Sistem operasi: Ubuntu $VERSION_ID"
        else
            print_error "Hanya Ubuntu yang didukung. Terdeteksi: $ID"
            exit 1
        fi
    else
        print_error "Tidak dapat mendeteksi sistem operasi."
        exit 1
    fi
}

# ============================================================
# VALIDASI .ENV
# ============================================================

validate_env() {
    local env_file="$INSTALL_DIR/.env"
    local missing=()
    local required_vars=("TELEGRAM_TOKEN" "AUTHORIZED_USER_ID" "GEMINI_API_KEY")
    
    if [[ ! -f "$env_file" ]]; then
        print_warning "File .env belum dibuat"
        return 1
    fi
    
    # Source file .env untuk membaca nilai
    set -a
    source "$env_file"
    set +a
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Konfigurasi .env BELUM LENGKAP"
        echo "  Variabel yang hilang:"
        for m in "${missing[@]}"; do
            echo "    - $m"
        done
        return 1
    fi
    
    print_success "✅ Semua konfigurasi .env LENGKAP"
    return 0
}

# ============================================================
# INSTALASI UTAMA
# ============================================================

main() {
    clear
    print_header "🚀 TELEGRAM FINANCE BOT - INSTALASI OTOMATIS v2.0"
    echo ""

    check_sudo
    check_internet
    check_os

    echo ""
    print_info "Memulai instalasi VPS..."

    # Clone/Update repository
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Meng-clone repository ke $INSTALL_DIR..."
        git clone https://github.com/RinaPython/Telegram-Finance-Bot.git "$INSTALL_DIR"
        print_success "Repository berhasil di-clone"
    else
        print_info "Repository sudah ada, memperbarui..."
        cd "$INSTALL_DIR"
        git pull --ff-only || print_warning "Gagal pull, melanjutkan..."
    fi

    # Jalankan install-vps.sh
    if [[ -f "$INSTALL_DIR/scripts/install-vps.sh" ]]; then
        bash "$INSTALL_DIR/scripts/install-vps.sh"
    else
        print_error "File install-vps.sh tidak ditemukan!"
        exit 1
    fi

    # Validasi .env setelah instalasi
    echo ""
    print_header "📋 VALIDASI KONFIGURASI"
    
    if validate_env; then
        # .env LENGKAP - Start bot
        echo ""
        print_info "Menjalankan Finance Bot..."
        cd "$INSTALL_DIR"
        if docker compose up -d; then
            print_success "✅ Finance Bot berhasil dijalankan"
        else
            print_error "Gagal menjalankan Finance Bot"
        fi
    else
        # .env BELUM LENGKAP - Dashboard only
        echo ""
        print_warning "Finance Bot TIDAK dijalankan karena konfigurasi belum lengkap."
        echo ""
        echo -e "${GREEN}✅ Finance Dashboard: TERINSTALL & AKTIF${NC}"
        echo -e "${YELLOW}⏸️  Finance Bot: MENUNGGU KONFIGURASI .env${NC}"
        echo ""
        print_info "Langkah selanjutnya:"
        echo "  1. Isi file .env: nano $INSTALL_DIR/.env"
        echo "  2. Jalankan dashboard: finance-dashboard"
        echo "  3. Setelah .env lengkap, start bot: cd $INSTALL_DIR && docker compose up -d"
    fi

    echo ""
    print_header "✅ INSTALASI SELESAI"
    echo ""
    echo -e "${GREEN}Dashboard:${NC} finance-dashboard"
    echo -e "${GREEN}Direktori:${NC} $INSTALL_DIR"
    echo ""
}

# ============================================================
# EKSEKUSI
# ============================================================

main
