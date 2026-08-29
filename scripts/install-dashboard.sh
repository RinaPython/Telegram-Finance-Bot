#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI DASHBOARD v2.0
# ============================================================

set -Eeuo pipefail

# ============================================================
# KONFIGURASI
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
TARGET="/usr/local/bin/finance-dashboard"

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================
# FUNGSI
# ============================================================

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini HARUS dijalankan dengan sudo."
        exit 1
    fi
}

install_dashboard() {
    # Idempotent check
    if [[ -f "$TARGET" ]]; then
        print_success "Dashboard sudah terinstall di $TARGET"
        return 0
    fi
    
    print_info "Menginstall Finance Dashboard..."
    
    local source_file="$INSTALL_DIR/dashboard/finance-dashboard.sh"
    
    if [[ ! -f "$source_file" ]]; then
        print_error "File dashboard tidak ditemukan: $source_file"
        exit 1
    fi
    
    # Copy dan set permission
    cp "$source_file" "$TARGET"
    chmod 755 "$TARGET"
    
    print_success "Dashboard berhasil diinstall ke $TARGET"
    print_info "Untuk menjalankan: finance-dashboard"
}

# ============================================================
# EKSEKUSI
# ============================================================

main() {
    check_sudo
    install_dashboard
}

main
