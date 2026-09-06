#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - START APP v2.0
# ============================================================
# Build & start container HANYA jika credential valid
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
SCRIPT_DIR="$INSTALL_DIR/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# STEP 1: VALIDASI KONFIGURASI
# ============================================================

print_info "Memeriksa validasi konfigurasi..."

if [[ ! -f "$SCRIPT_DIR/validate-config.sh" ]]; then
    print_error "Script validate-config.sh tidak ditemukan."
    exit 1
fi

# Jalankan validasi (silent mode)
if bash "$SCRIPT_DIR/validate-config.sh" "silent"; then
    print_success "Konfigurasi VALID. Melanjutkan build..."
else
    print_warning "Konfigurasi TIDAK VALID. Bot TIDAK akan dijalankan."
    echo ""
    print_info "Masuk ke WAITING MODE."
    echo ""
    print_info "Langkah selanjutnya:"
    echo "  1. Perbaiki file .env: nano $INSTALL_DIR/.env"
    echo "  2. Jalankan installer ulang: sudo bash $INSTALL_DIR/install.sh"
    echo "  3. Atau gunakan dashboard: finance-dashboard"
    echo ""
    exit 1  # Exit dengan non-zero untuk WAITING MODE
fi

# ============================================================
# STEP 2: BUILD DOCKER IMAGE
# ============================================================

print_info "Membangun Docker image..."
cd "$INSTALL_DIR"

if docker compose build --no-cache 2>&1 | tail -30; then
    print_success "Build berhasil."
else
    print_error "Build gagal."
    echo ""
    print_info "Log lengkap build:"
    docker compose build --no-cache 2>&1 | tail -50
    echo ""
    print_info "Periksa Dockerfile dan dependency."
    exit 1
fi

# ============================================================
# STEP 3: START CONTAINER
# ============================================================

print_info "Menjalankan container..."
if docker compose up -d; then
    print_success "Container berhasil dijalankan."
else
    print_error "Gagal menjalankan container."
    echo ""
    print_info "Log error:"
    docker compose logs --tail=30
    exit 1
fi

# ============================================================
# STEP 4: VERIFIKASI CONTAINER
# ============================================================

print_info "Menunggu container stabil (10 detik)..."
sleep 10

# Cek status container
if docker compose ps | grep -q "Up"; then
    print_success "Container berjalan."
else
    print_error "Container gagal berjalan."
    echo ""
    print_info "Log container:"
    docker compose logs --tail=30
    exit 1
fi

# ============================================================
# STEP 5: HEALTH CHECK (PANGGIL SCRIPT TERPISAH)
# ============================================================

print_info "Menjalankan health check..."
if [[ -f "$SCRIPT_DIR/health-check.sh" ]]; then
    if bash "$SCRIPT_DIR/health-check.sh"; then
        print_success "Health check PASSED."
    else
        print_warning "Health check FAILED, tetapi container tetap running."
        print_info "Periksa log untuk detail: docker compose logs --tail=50"
    fi
else
    print_warning "Script health-check.sh tidak ditemukan."
fi

echo ""
print_success "✅ Bot berhasil dijalankan (dengan konfigurasi valid)."