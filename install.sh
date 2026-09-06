#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - INSTALLER UTAMA v3.3
# ============================================================
# Penggunaan: curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/install.sh | sudo bash
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
SCRIPT_DIR="$INSTALL_DIR/scripts"
REPO_URL="https://github.com/RinaPython/Telegram-Finance-Bot.git"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${WHITE}${BOLD}TELEGRAM FINANCE BOT - INSTALLATION WIZARD${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }
print_step() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}>>> $1${NC}"; }

ensure_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script $script_name tidak ditemukan di $SCRIPT_DIR"
        exit 1
    fi
    
    chmod +x "$script_path"
}

run_script() {
    local script_name="$1"
    shift
    local script_path="$SCRIPT_DIR/$script_name"
    
    ensure_script "$script_name"
    
    if ! bash "$script_path" "$@"; then
        print_error "Script $script_name gagal dijalankan."
        exit 1
    fi
}

# ============================================================
# BOOTSTRAP AWAL
# ============================================================

bootstrap_environment() {
    print_step "[1/6] Bootstrapping lingkungan..."

    if [[ $EUID -ne 0 ]]; then
        print_error "Installer harus dijalankan dengan sudo atau sebagai root."
        echo "Gunakan: curl -fsSL <url> | sudo bash"
        exit 1
    fi
    print_success "Hak akses root/sudo terkonfirmasi."

    print_info "Memastikan git dan curl tersedia..."
    apt-get update -qq
    if ! command -v git &> /dev/null; then
        print_info "Menginstall git..."
        apt-get install -y -qq git
    fi
    if ! command -v curl &> /dev/null; then
        print_info "Menginstall curl..."
        apt-get install -y -qq curl
    fi
    print_success "git dan curl tersedia."

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    if [[ -d "$INSTALL_DIR/.git" ]]; then
        print_success "Repository sudah ada di $INSTALL_DIR."
        print_info "Memeriksa remote origin..."
        if git remote get-url origin 2>/dev/null | grep -q "RinaPython/Telegram-Finance-Bot"; then
            print_success "Remote origin benar."
        else
            print_warning "Remote origin tidak sesuai. Mengatur ulang..."
            git remote set-url origin "$REPO_URL"
        fi

        # ============================================================
        # CEK PERUBAHAN LOKAL - MENGGUNAKAN git status --porcelain
        # ============================================================
        if [[ -n "$(git status --porcelain)" ]]; then
            print_error "❌ Ada perubahan lokal yang belum di-commit."
            echo ""
            echo "Perubahan lokal yang terdeteksi:"
            git status --short
            echo ""
            echo "Installer tidak dapat melanjutkan karena perubahan lokal."
            echo ""
            echo "Silakan selesaikan perubahan lokal terlebih dahulu,"
            echo "kemudian jalankan installer ulang."
            exit 1
        fi

        print_info "Menarik update dari repository..."
        if git pull --ff-only; then
            print_success "Repository berhasil diperbarui."
        else
            print_error "Gagal menarik update. Periksa koneksi atau repository."
            exit 1
        fi
    else
        print_info "Meng-clone repository..."
        if git clone "$REPO_URL" .; then
            print_success "Repository berhasil di-clone."
        else
            print_error "Gagal meng-clone repository. Periksa koneksi internet."
            exit 1
        fi
    fi

    print_info "Membuat direktori data, logs, backups, secrets..."
    mkdir -p data logs backups secrets
    chmod 755 data logs backups
    chmod 700 secrets
    print_success "Direktori aplikasi siap."
}

# ============================================================
# MAIN
# ============================================================

main() {
    print_header
    
    bootstrap_environment
    
    print_step "[2/6] Memeriksa VPS (check-system)..."
    run_script "check-system.sh"

    print_step "[3/6] Memasang Docker (install-docker)..."
    run_script "install-docker.sh"

    print_step "[4/6] Menyiapkan konfigurasi (setup-config)..."
    run_script "setup-config.sh"

    print_step "[5/6] Memvalidasi konfigurasi (validate-config)..."
    if ! run_script "validate-config.sh" "silent"; then
        print_warning "Konfigurasi belum valid. Bot akan masuk WAITING MODE."
        print_info "Silakan lengkapi konfigurasi dan jalankan installer ulang."
        print_info "Atau gunakan dashboard: finance-dashboard"
        echo ""
        print_info "File .env berada di: $INSTALL_DIR/.env"
        run_script "dashboard.sh" "install"
        print_final_waiting
        exit 0
    fi

    print_step "[6/6] Menjalankan bot (start-app)..."
    run_script "start-app.sh"
    run_script "health-check.sh"
    run_script "dashboard.sh" "install"
    
    print_final_success
}

print_final_success() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${GREEN}${BOLD}✅ INSTALASI SELESAI!${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}📌 Informasi:${NC}"
    echo -e "  ${GREEN}•${NC} Direktori: ${WHITE}$INSTALL_DIR${NC}"
    echo -e "  ${GREEN}•${NC} Dashboard: ${WHITE}finance-dashboard${NC}"
    echo -e "  ${GREEN}•${NC} Status:    ${GREEN}BOT BERJALAN${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}📋 Perintah yang tersedia:${NC}"
    echo -e "  ${YELLOW}•${NC} finance-dashboard    # Menu kontrol bot"
    echo -e "  ${YELLOW}•${NC} cd $INSTALL_DIR && ./update.sh   # Update aplikasi"
    echo -e "  ${YELLOW}•${NC} cd $INSTALL_DIR && ./backup.sh   # Backup data"
    echo -e "  ${YELLOW}•${NC} cd $INSTALL_DIR && ./uninstall.sh # Hapus aplikasi"
    echo ""
    echo -e "${WHITE}${BOLD}🔗 Mulai menggunakan bot di Telegram!${NC}"
    echo ""
}

print_final_waiting() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${YELLOW}${BOLD}⚠️  WAITING MODE${NC}                                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}📌 Informasi:${NC}"
    echo -e "  ${YELLOW}•${NC} Direktori: ${WHITE}$INSTALL_DIR${NC}"
    echo -e "  ${YELLOW}•${NC} Dashboard: ${WHITE}finance-dashboard${NC}"
    echo -e "  ${YELLOW}•${NC} Status:    ${YELLOW}MENUNGGU KONFIGURASI${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}📋 Langkah selanjutnya:${NC}"
    echo -e "  ${YELLOW}1.${NC} Lengkapi file .env: ${WHITE}nano $INSTALL_DIR/.env${NC}"
    echo -e "  ${YELLOW}2.${NC} Jalankan installer ulang: ${WHITE}sudo bash $INSTALL_DIR/install.sh${NC}"
    echo -e "  ${YELLOW}3.${NC} Atau gunakan dashboard: ${WHITE}finance-dashboard${NC}"
    echo ""
}

trap 'echo -e "\n${RED}❌ Instalasi gagal. Periksa log di atas.${NC}"; exit 1' ERR

main