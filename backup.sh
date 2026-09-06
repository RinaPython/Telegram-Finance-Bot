#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - BACKUP SCRIPT v2.0
# ============================================================
# Backup data dengan aman, gagal jika ada error
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
BACKUP_DIR="$INSTALL_DIR/backups"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/finance-bot-$TIMESTAMP.tar.gz"

# Warna
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
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}💾 BACKUP TELEGRAM FINANCE BOT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================
# CEK DIREKTORI
# ============================================================
print_header

if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Direktori tidak ditemukan: $INSTALL_DIR"
    exit 1
fi

# Buat direktori backup
mkdir -p "$BACKUP_DIR"
cd "$INSTALL_DIR"

print_info "Membuat backup ke: ${WHITE}$BACKUP_FILE${NC}"
echo ""

# ============================================================
# BUAT BACKUP (TANPA || true)
# ============================================================
print_info "Mengumpulkan file untuk backup..."

# Cek file/direktori yang akan di-backup
FILES_TO_BACKUP=""
[[ -f .env ]] && FILES_TO_BACKUP="$FILES_TO_BACKUP .env"
[[ -d data ]] && FILES_TO_BACKUP="$FILES_TO_BACKUP data"
[[ -d secrets ]] && FILES_TO_BACKUP="$FILES_TO_BACKUP secrets"

if [[ -z "$FILES_TO_BACKUP" ]]; then
    print_error "Tidak ada data yang dapat dibackup (.env, data/, secrets/ tidak ditemukan)"
    exit 1
fi

print_info "File yang akan dibackup: $FILES_TO_BACKUP"

# Eksekusi tar - TANPA || true
print_info "Menjalankan tar..."
if ! tar -czf "$BACKUP_FILE" \
    --exclude="backups" \
    --exclude="logs" \
    --exclude="*.pyc" \
    --exclude="__pycache__" \
    --exclude=".git" \
    --exclude="*.tar.gz" \
    $FILES_TO_BACKUP 2>/dev/null; then
    print_error "Gagal membuat backup (tar error)"
    # Hapus file backup yang mungkin korup
    [[ -f "$BACKUP_FILE" ]] && rm -f "$BACKUP_FILE"
    exit 1
fi

# ============================================================
# VERIFIKASI BACKUP
# ============================================================
if [[ ! -f "$BACKUP_FILE" ]]; then
    print_error "Backup gagal - file tidak ditemukan setelah tar"
    exit 1
fi

# Cek ukuran file
FILE_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE" 2>/dev/null || echo "0")
if [[ "$FILE_SIZE" -eq 0 ]]; then
    print_error "Backup gagal - file kosong"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Set permission
chmod 600 "$BACKUP_FILE"
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

# ============================================================
# HASIL
# ============================================================
print_success "✅ Backup selesai!"
echo ""
echo -e "${WHITE}📋 Detail:${NC}"
echo -e "  File: ${WHITE}$BACKUP_FILE${NC}"
echo -e "  Ukuran: ${WHITE}$SIZE${NC}"
echo -e "  Permission: ${WHITE}600${NC}"

# Tampilkan daftar backup terakhir
echo ""
echo -e "${WHITE}📋 Backup tersimpan:${NC}"
ls -lh "$BACKUP_DIR" | tail -5 | awk '{print "  " $9 " (" $5 ")"}'

echo ""
print_success "Backup berhasil disimpan."
exit 0