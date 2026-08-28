#!/bin/bash

# ============================================================
# TELEGRAM FINANCE BOT - BOOTSTRAP INSTALLER
# ============================================================
# Script ini adalah pintu masuk utama untuk instalasi otomatis
# di VPS Ubuntu baru.
#
# Penggunaan:
#   curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/scripts/bootstrap.sh | sudo bash
# ============================================================

set -Eeuo pipefail

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# FUNGSI UTILITY
# ============================================================

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_error() {
    echo -e "${RED}[✗] ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

# ============================================================
# CEK HAK SUDO
# ============================================================

check_sudo() {
    print_info "Memeriksa hak akses root/sudo..."
    
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini HARUS dijalankan dengan sudo atau sebagai root."
        echo "Gunakan: curl -fsSL <url> | sudo bash"
        exit 1
    fi
    
    print_success "Hak akses root/sudo terkonfirmasi"
}

# ============================================================
# CEK KONEKSI INTERNET
# ============================================================

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
    echo "  4. Pastikan VPS memiliki akses internet keluar."
    echo ""
    exit 1
}

# ============================================================
# CEK SISTEM OPERASI
# ============================================================

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
# FUNGSI UTAMA
# ============================================================

main() {
    clear
    print_header "🚀 TELEGRAM FINANCE BOT - INSTALASI OTOMATIS"
    echo ""
    echo "Repository: https://github.com/RinaPython/Telegram-Finance-Bot"
    echo "Target: VPS Ubuntu 22.04 LTS"
    echo ""
    
    # Jalankan semua pemeriksaan prasyarat
    check_sudo
    check_internet
    check_os
    
    echo ""
    print_info "Semua pemeriksaan prasyarat BERHASIL."
    print_info "Memulai instalasi VPS..."
    echo ""
    
    # Tentukan direktori instalasi
    INSTALL_DIR="/opt/Telegram-Finance-Bot"
    
    # Clone repository jika belum ada
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Meng-clone repository ke $INSTALL_DIR..."
        git clone https://github.com/RinaPython/Telegram-Finance-Bot.git "$INSTALL_DIR"
        print_success "Repository berhasil di-clone"
    else
        print_info "Repository sudah ada di $INSTALL_DIR, melanjutkan..."
    fi
    
    # Pastikan script instalasi utama dapat diakses
    if [[ ! -f "$INSTALL_DIR/scripts/install-vps.sh" ]]; then
        print_error "File scripts/install-vps.sh tidak ditemukan di $INSTALL_DIR"
        echo "Pastikan repository berhasil di-clone dengan benar."
        exit 1
    fi
    
    # Jalankan script instalasi utama
    print_info "Menjalankan install-vps.sh..."
    echo ""
    
    if bash "${INSTALL_DIR}/scripts/install-vps.sh"; then
        echo ""
        print_success "✅ INSTALASI SELESAI!"
        echo ""
        echo "Langkah selanjutnya:"
        echo "  1. Buka file .env: nano $INSTALL_DIR/.env"
        echo "  2. Isi dengan kredensial Anda (Telegram Token, Gemini API Key, dll.)"
        echo "  3. Jalankan dashboard: finance-dashboard"
        echo "  4. Atau start bot: docker compose -f $INSTALL_DIR/docker-compose.yml up -d"
        echo ""
        print_info "Bot akan otomatis berjalan setelah .env diisi dengan benar."
        echo ""
    else
        echo ""
        print_error "❌ INSTALASI GAGAL!"
        echo "Periksa log di atas untuk mengetahui penyebab kegagalan."
        echo "Anda dapat mencoba menjalankan ulang: sudo bash $INSTALL_DIR/scripts/install-vps.sh"
        exit 1
    fi
}

# ============================================================
# EKSEKUSI
# ============================================================

main
