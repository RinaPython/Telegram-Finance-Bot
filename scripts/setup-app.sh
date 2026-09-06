#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - SETUP APP v2.3
# ============================================================
# Setup repository dengan aman - tanpa git stash
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
REPO_URL="https://github.com/RinaPython/Telegram-Finance-Bot.git"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# MAIN
# ============================================================

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    print_success "Repository sudah ada."
    
    if git remote get-url origin 2>/dev/null | grep -q "RinaPython/Telegram-Finance-Bot"; then
        print_info "Remote origin benar."
    else
        print_warning "Remote origin tidak sesuai. Mengatur ulang..."
        git remote set-url origin "$REPO_URL"
    fi
    
    # ============================================================
    # CEK PERUBAHAN LOKAL - TANPA AUTO-STASH ATAU FORCE RESET
    # ============================================================
    if [[ -n "$(git status --porcelain)" ]]; then
        print_error "❌ Ada perubahan lokal yang belum di-commit."
        echo ""
        echo "Perubahan lokal yang terdeteksi:"
        git status --short
        echo ""
        echo "Setup/Update DIBATALKAN untuk melindungi data Anda."
        echo ""
        echo "Silakan selesaikan perubahan lokal terlebih dahulu,"
        echo "kemudian jalankan installer/update lagi."
        exit 1
    fi
    
    print_info "Memperbarui repository..."
    if git pull --ff-only 2>/dev/null; then
        print_success "Repository diperbarui."
    else
        print_warning "Gagal pull update (mungkin konflik atau bukan fast-forward)."
        print_info "Melanjutkan dengan kode yang ada."
    fi
else
    print_info "Meng-clone repository..."
    if git clone "$REPO_URL" . 2>/dev/null; then
        print_success "Repository berhasil di-clone."
    else
        print_error "Gagal meng-clone repository."
        exit 1
    fi
fi

print_info "Memastikan direktori data, logs, backups, secrets ada..."
mkdir -p data logs backups secrets
chmod 755 data logs backups
chmod 700 secrets

print_success "Aplikasi siap di $INSTALL_DIR"