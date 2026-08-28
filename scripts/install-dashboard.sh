#!/bin/bash

# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI DASHBOARD VPS
# ============================================================
# Script ini menginstall dashboard interaktif untuk mengelola
# bot dari terminal.
#
# Penggunaan:
#   sudo bash scripts/install-dashboard.sh
# ============================================================

set -Eeuo pipefail

# ============================================================
# VARIABEL GLOBAL
# ============================================================

# Direktori instalasi (harus sama dengan install-vps.sh)
INSTALL_DIR="/opt/Telegram-Finance-Bot"

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
        exit 1
    fi
    
    print_success "Hak akses root/sudo terkonfirmasi"
}

# ============================================================
# CEK IDEMPOTENCY
# ============================================================

check_idempotent() {
    if [[ -f "/usr/local/bin/finance-dashboard" ]]; then
        print_success "Dashboard sudah terinstall di /usr/local/bin/finance-dashboard"
        print_info "Melewati proses instalasi"
        return 1
    fi
    return 0
}

# ============================================================
# INSTALASI DASHBOARD
# ============================================================

install_dashboard() {
    print_info "Menginstall Dashboard VPS..."
    
    local dashboard_source="$INSTALL_DIR/dashboard/finance-dashboard.sh"
    local dashboard_target="/usr/local/bin/finance-dashboard"
    
    # Pastikan source file ada
    if [[ ! -f "$dashboard_source" ]]; then
        print_error "File dashboard tidak ditemukan: $dashboard_source"
        exit 1
    fi
    
    # Copy dashboard ke /usr/local/bin
    cp "$dashboard_source" "$dashboard_target"
    
    # Set permission executable
    chmod 755 "$dashboard_target"
    
    print_success "Dashboard berhasil diinstall ke $dashboard_target"
}

# ============================================================
# VERIFIKASI
# ============================================================

verify_installation() {
    print_info "Memverifikasi instalasi..."
    
    if [[ -x "/usr/local/bin/finance-dashboard" ]]; then
        print_success "Dashboard siap digunakan"
        echo ""
        echo "Untuk menjalankan dashboard, ketik:"
        echo -e "${GREEN}finance-dashboard${NC}"
        echo ""
    else
        print_error "Dashboard tidak dapat dieksekusi"
        exit 1
    fi
}

# ============================================================
# FUNGSI UTAMA
# ============================================================

main() {
    clear
    print_header "🖥️ INSTALASI DASHBOARD VPS"
    echo ""
    
    # Pemeriksaan prasyarat
    check_sudo
    
    # Cek idempotency
    if check_idempotent; then
        # Proses instalasi
        install_dashboard
        verify_installation
    else
        echo ""
        print_success "Dashboard sudah siap digunakan"
        echo ""
        echo "Untuk menjalankan dashboard, ketik:"
        echo -e "${GREEN}finance-dashboard${NC}"
        echo ""
    fi
}

# ============================================================
# EKSEKUSI
# ============================================================

main
