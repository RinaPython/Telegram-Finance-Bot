#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - UPDATE SCRIPT v2.8
# ============================================================
# Update aplikasi dengan aman - WAITING MODE jika validator tidak ada
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
SCRIPT_DIR="$INSTALL_DIR/scripts"
BACKUP_DIR="$INSTALL_DIR/backups"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}⟳ UPDATE TELEGRAM FINANCE BOT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Direktori tidak ditemukan: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# ============================================================
# 1. BACKUP .ENV - DISIMPAN DI backups/
# ============================================================
print_info "Backup .env..."
if [[ -f .env ]]; then
    mkdir -p "$BACKUP_DIR"
    chmod 755 "$BACKUP_DIR"
    
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/env-backup-$BACKUP_TIMESTAMP.env"
    
    cp .env "$BACKUP_FILE"
    chmod 600 "$BACKUP_FILE"
    print_success ".env dibackup ke: $BACKUP_FILE"
else
    print_warning ".env tidak ditemukan, backup dilewati"
fi

# ============================================================
# 2. CEK PERUBAHAN LOKAL - MENGGUNAKAN git status --porcelain
# ============================================================
print_info "Memeriksa perubahan lokal..."

if [[ -n "$(git status --porcelain)" ]]; then
    print_error "❌ Ada perubahan lokal yang belum di-commit."
    echo ""
    echo "Perubahan lokal yang terdeteksi:"
    git status --short
    echo ""
    echo "UPDATE DIBATALKAN untuk melindungi data dan perubahan Anda."
    echo ""
    echo "Silakan selesaikan perubahan lokal terlebih dahulu,"
    echo "kemudian jalankan update.sh lagi."
    exit 1
fi

# ============================================================
# 3. GIT PULL (FF-ONLY)
# ============================================================
print_info "Mengambil update dari GitHub (git pull --ff-only)..."

if git pull --ff-only; then
    print_success "Git pull berhasil"
else
    print_error "Git pull gagal (mungkin ada konflik atau bukan fast-forward)"
    echo ""
    echo "Kemungkinan penyebab:"
    echo "  1. Remote branch memiliki perubahan yang tidak sejalan dengan lokal"
    echo "  2. Ada konflik yang tidak dapat diselesaikan secara otomatis"
    echo ""
    echo "Solusi yang disarankan:"
    echo "  - Coba: git fetch && git log --oneline origin/main..HEAD"
    echo "  - Perbaiki konflik secara manual jika ada"
    echo ""
    print_error "UPDATE DIBATALKAN"
    exit 1
fi

# ============================================================
# 4. DOCKER BUILD
# ============================================================
print_info "Membangun ulang Docker image..."
if docker compose build --no-cache 2>&1 | tail -30; then
    print_success "Build berhasil"
else
    print_error "Build gagal"
    echo ""
    print_info "Log lengkap build:"
    docker compose build --no-cache 2>&1 | tail -50
    print_error "UPDATE GAGAL"
    exit 1
fi

# ============================================================
# 5. VALIDASI KONFIGURASI - WAITING MODE JIKA VALIDATOR TIDAK ADA
# ============================================================
print_info "Memeriksa validasi konfigurasi..."

# DEFAULT: TIDAK VALID - WAITING MODE
CONFIG_VALID=false

if [[ ! -f "$SCRIPT_DIR/validate-config.sh" ]]; then
    print_error "❌ Script validate-config.sh tidak ditemukan."
    print_warning "Bot TIDAK akan dijalankan (WAITING MODE)"
    echo ""
    print_info "File yang hilang: $SCRIPT_DIR/validate-config.sh"
    print_info "Perbaiki instalasi dan jalankan update.sh lagi."
else
    if bash "$SCRIPT_DIR/validate-config.sh" "silent"; then
        print_success "Konfigurasi VALID. Bot akan dijalankan."
        CONFIG_VALID=true
    else
        print_warning "Konfigurasi TIDAK VALID. Bot akan masuk WAITING MODE."
        echo ""
        print_info "File .env: $INSTALL_DIR/.env"
        print_info "Perbaiki konfigurasi dan jalankan update.sh lagi."
        CONFIG_VALID=false
    fi
fi

# ============================================================
# 6. STOP & START CONTAINER - HANYA JIKA VALID
# ============================================================
if [[ "$CONFIG_VALID" == true ]]; then
    print_info "Merestart container..."
    docker compose down
    docker compose up -d
    
    print_info "Menunggu container stabil (10 detik)..."
    sleep 10
    
    if [[ -f "$SCRIPT_DIR/health-check.sh" ]]; then
        print_info "Menjalankan health check..."
        if bash "$SCRIPT_DIR/health-check.sh"; then
            print_success "✅ UPDATE BERHASIL - Bot sehat"
        else
            print_warning "⚠️ UPDATE BERHASIL - Bot berjalan, tetapi health check warning"
            echo ""
            print_info "Periksa log: docker compose logs --tail=50"
        fi
    else
        print_warning "Script health-check.sh tidak ditemukan."
        print_info "Pastikan container berjalan: docker compose ps"
    fi
else
    print_warning "⚠️ UPDATE SELESAI - Bot TIDAK dijalankan (WAITING MODE)"
    echo ""
    print_info "Langkah selanjutnya:"
    print_info "  1. Perbaiki .env: nano $INSTALL_DIR/.env"
    print_info "  2. Jalankan update.sh lagi"
    print_info "  3. Atau perbaiki instalasi jika validator hilang"
fi

echo ""
if [[ "$CONFIG_VALID" == true ]]; then
    print_success "✅ UPDATE SELESAI"
else
    print_warning "⚠️ UPDATE SELESAI (WAITING MODE)"
fi