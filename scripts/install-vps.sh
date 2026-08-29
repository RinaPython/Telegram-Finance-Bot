#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI VPS v2.0
# ============================================================
# Script ini menginstal dependency VPS, Docker, dan Dashboard
# TANPA build atau start Finance Bot.
# ============================================================

set -Eeuo pipefail

# ============================================================
# KONFIGURASI
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# FUNGSI UTILITY
# ============================================================

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# CEK PRASYARAT
# ============================================================

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini HARUS dijalankan dengan sudo."
        exit 1
    fi
    print_success "Hak akses root/sudo terkonfirmasi"
}

check_internet() {
    print_info "Memeriksa koneksi internet..."
    local test_urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://api.github.com"
    )
    for url in "${test_urls[@]}"; do
        if curl -4 -sSf --connect-timeout 5 --max-time 10 -o /dev/null "$url" 2>/dev/null; then
            print_success "Koneksi internet: OK (${url})"
            return 0
        fi
    done
    print_error "Koneksi internet: GAGAL"
    echo "Diagnostik: Periksa DNS, Firewall (port 443), atau Proxy."
    exit 1
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "OS: Ubuntu $VERSION_ID"
        else
            print_error "Hanya Ubuntu yang didukung. Terdeteksi: $ID"
            exit 1
        fi
    else
        print_error "Tidak dapat mendeteksi OS."
        exit 1
    fi
}

# ============================================================
# INSTALASI DEPENDENCY (IDEMPOTENT)
# ============================================================

install_git() {
    if command -v git &> /dev/null; then
        print_success "Git sudah terinstall"
        return 0
    fi
    print_info "Menginstall Git..."
    apt-get update -qq
    apt-get install -y -qq git
    print_success "Git berhasil diinstall"
}

install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker sudah terinstall"
        return 0
    fi
    
    print_info "Menginstall Docker..."
    
    # Hapus paket lama jika ada
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisite
    apt-get update -qq
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Tambahkan GPG key Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Tambahkan repository Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update -qq
    apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    # Start dan enable Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker berhasil diinstall"
}

# ============================================================
# SETUP .env (TIDAK MENIMPA)
# ============================================================

setup_env() {
    print_info "Memeriksa file .env..."
    local env_file="$INSTALL_DIR/.env"
    
    if [[ -f "$env_file" ]]; then
        print_success "File .env sudah ada, tidak akan ditimpa"
        return 0
    fi
    
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
        cp "$INSTALL_DIR/.env.example" "$env_file"
        print_success "File .env dibuat dari .env.example"
        print_warning "⚠️  .env masih kosong, isi dengan kredensial Anda"
        echo ""
        print_info "Variabel WAJIB yang harus diisi:"
        echo "  - TELEGRAM_TOKEN"
        echo "  - AUTHORIZED_USER_ID"
        echo "  - GEMINI_API_KEY"
        echo ""
        print_info "Variabel OPSIONAL (bot tetap jalan tanpa ini):"
        echo "  - SPREADSHEET_ID"
        echo "  - GOOGLE_SHEETS_CREDENTIALS_JSON"
        echo "  - DELETE_MESSAGES"
        echo "  - HISTORY_PAGE_SIZE"
        echo "  - TZ"
        echo "  - LOG_LEVEL"
        echo ""
    else
        print_error "File .env.example tidak ditemukan!"
        exit 1
    fi
}

# ============================================================
# SETUP DIREKTORI
# ============================================================

setup_directories() {
    print_info "Menyiapkan direktori data dan logs..."
    mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/data" "$INSTALL_DIR/logs"
    print_success "Direktori data dan logs siap"
}

# ============================================================
# INSTALASI DASHBOARD (IDEMPOTENT)
# ============================================================

install_dashboard() {
    if [[ -f "/usr/local/bin/finance-dashboard" ]]; then
        print_success "Dashboard sudah terinstall"
        return 0
    fi
    
    print_info "Menginstall Finance Dashboard..."
    local dashboard_script="$INSTALL_DIR/scripts/install-dashboard.sh"
    
    if [[ -f "$dashboard_script" ]]; then
        bash "$dashboard_script"
        print_success "Dashboard berhasil diinstall"
    else
        print_error "File install-dashboard.sh tidak ditemukan"
        exit 1
    fi
}

# ============================================================
# FUNGSI UTAMA
# ============================================================

main() {
    clear
    print_header "🔄 INSTALASI VPS - TELEGRAM FINANCE BOT"
    echo ""

    check_sudo
    check_internet
    check_os

    echo ""
    print_header "📦 INSTALASI DEPENDENCY"
    install_git
    install_docker

    echo ""
    print_header "📁 SETUP PROJECT"
    setup_directories
    setup_env

    echo ""
    print_header "🖥️ INSTALASI DASHBOARD"
    install_dashboard

    echo ""
    print_header "✅ INSTALASI VPS SELESAI"
    echo ""
    echo "📋 Catatan:"
    echo "  - Finance Dashboard: ✅ TERINSTALL"
    echo "  - Finance Bot: ⏸️ BELUM DIJALANKAN (menunggu .env lengkap)"
    echo ""
    echo "⚠️  JANGAN build/start bot di sini - ini tugas bootstrap.sh"
    echo ""
}

# ============================================================
# EKSEKUSI
# ============================================================

main
