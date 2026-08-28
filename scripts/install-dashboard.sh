#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI DASHBOARD v2.0
# ============================================================

set -Eeuo pipefail

INSTALL_DIR="/opt/Telegram-Finance-Bot"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    if [[ -f "/usr/local/bin/finance-dashboard" ]]; then
        print_success "Dashboard sudah terinstall di /usr/local/bin/finance-dashboard"
        return 0
    fi
    
    print_info "Menginstall Finance Dashboard..."
    
    local source_file="$INSTALL_DIR/dashboard/finance-dashboard.sh"
    local target_file="/usr/local/bin/finance-dashboard"
    
    if [[ ! -f "$source_file" ]]; then
        print_error "File dashboard tidak ditemukan: $source_file"
        exit 1
    fi
    
    cp "$source_file" "$target_file"
    chmod 755 "$target_file"
    
    print_success "Dashboard berhasil diinstall ke $target_file"
    print_info "Untuk menjalankan: finance-dashboard"
}

main() {
    check_sudo
    install_dashboard
}

main
