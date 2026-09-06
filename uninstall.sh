#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - UNINSTALL SCRIPT v2.2
# ============================================================
# Uninstall dengan error handling yang baik
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    echo -e "${RED}${BOLD}⚠️  UNINSTALL TELEGRAM FINANCE BOT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

if [[ ! -d "$INSTALL_DIR" ]]; then
    print_warning "Direktori tidak ditemukan: $INSTALL_DIR"
    echo ""
    echo "Mungkin aplikasi sudah dihapus atau tidak terinstall."
    exit 0
fi

print_header

echo -e "${RED}${BOLD}PERINGATAN!${NC}"
echo "Anda akan menghapus Telegram Finance Bot dari VPS ini."
echo ""

echo "Pilih opsi:"
echo -e "  ${CYAN}[1]${NC} Hapus aplikasi, tapi ${GREEN}simpan data${NC} (.env, data/, secrets/, backups/)"
echo -e "  ${CYAN}[2]${NC} Hapus aplikasi ${RED}DAN SEMUA DATA${NC} (tidak dapat dikembalikan)"
echo -e "  ${CYAN}[3]${NC} Batal"
echo ""
read -p "Pilihan [1/2/3]: " choice

case $choice in
    1)
        echo ""
        print_info "Mode: Hapus aplikasi, simpan data"
        echo ""
        
        cd "$INSTALL_DIR"
        print_info "Menghentikan container (tanpa -v)..."
        if docker compose down 2>/dev/null; then
            print_success "Container berhasil dihentikan."
        else
            print_warning "Container tidak berjalan atau sudah dihentikan."
        fi
        
        print_info "Menghapus file aplikasi..."
        # Hapus file aplikasi, pertahankan data
        rm -rf src/ scripts/ Dockerfile docker-compose.yml \
            .env.example install.sh update.sh backup.sh uninstall.sh \
            2>/dev/null || true
        
        rm -f /usr/local/bin/finance-dashboard 2>/dev/null || true
        
        echo ""
        print_success "✅ Aplikasi dihapus."
        echo ""
        echo -e "${GREEN}Data tetap disimpan di:${NC}"
        echo "  ${WHITE}$INSTALL_DIR/.env${NC}"
        echo "  ${WHITE}$INSTALL_DIR/data/${NC}"
        echo "  ${WHITE}$INSTALL_DIR/secrets/${NC}"
        echo "  ${WHITE}$INSTALL_DIR/backups/${NC}"
        echo ""
        print_info "Untuk menginstall ulang, jalankan installer."
        ;;
        
    2)
        echo ""
        echo -e "${RED}${BOLD}⚠️  PERINGATAN AKHIR${NC}"
        echo "Anda akan MENGHAPUS SEMUA DATA secara permanen."
        echo "Tindakan ini TIDAK DAPAT DIBATALKAN."
        echo ""
        echo -n "Ketik 'HAPUS SEMUA' untuk melanjutkan: "
        read -r confirm
        
        if [[ "$confirm" == "HAPUS SEMUA" ]]; then
            echo ""
            print_info "Menghapus semua data..."
            
            cd /opt
            print_info "Menghentikan dan menghapus container & volume..."
            if docker compose -f "$INSTALL_DIR/docker-compose.yml" down -v 2>/dev/null; then
                print_success "Container dan volume dihapus."
            else
                print_warning "Container tidak berjalan atau sudah dihapus."
            fi
            
            print_info "Menghapus direktori $INSTALL_DIR..."
            if rm -rf "$INSTALL_DIR"; then
                print_success "Direktori $INSTALL_DIR dihapus."
            else
                print_error "Gagal menghapus direktori $INSTALL_DIR"
                exit 1
            fi
            
            print_info "Menghapus dashboard..."
            if rm -f /usr/local/bin/finance-dashboard 2>/dev/null; then
                print_success "Dashboard dihapus."
            fi
            
            echo ""
            print_success "✅ Semua data dan aplikasi telah dihapus."
        else
            echo ""
            print_warning "❌ Dibatalkan. Tidak ada data yang dihapus."
            exit 0
        fi
        ;;
        
    *)
        echo ""
        print_warning "❌ Dibatalkan. Tidak ada data yang dihapus."
        exit 0
        ;;
esac

exit 0