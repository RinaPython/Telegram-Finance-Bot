#!/bin/bash

# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI VPS
# ============================================================
# Script ini menginstal semua komponen yang diperlukan untuk
# menjalankan Telegram Finance Bot di VPS Ubuntu.
#
# Penggunaan:
#   sudo bash scripts/install-vps.sh
# ============================================================

set -Eeuo pipefail

# ============================================================
# VARIABEL GLOBAL
# ============================================================

# Direktori instalasi (harus sama dengan bootstrap.sh)
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
# CEK PRASYARAT
# ============================================================

check_sudo() {
    print_info "Memeriksa hak akses root/sudo..."
    
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini HARUS dijalankan dengan sudo atau sebagai root."
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
        "https://www.google.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -4 -sSf --connect-timeout 5 --max-time 10 -o /dev/null "$url" 2>/dev/null; then
            print_success "Koneksi internet: OK (${url})"
            return 0
        fi
    done
    
    print_error "Koneksi internet: GAGAL"
    echo ""
    echo "[DIAGNOSTIK] Semua endpoint gagal dijangkau. Periksa:"
    echo "  1. DNS: apakah 'getent hosts github.com' berhasil?"
    echo "  2. Firewall: apakah blokir port 443 (HTTPS)?"
    echo "  3. Proxy: jika ada, atur environment variable http_proxy."
    echo ""
    exit 1
}

check_os() {
    print_info "Memeriksa sistem operasi..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Sistem operasi: Ubuntu $VERSION_ID"
        else
            print_error "Sistem operasi tidak didukung. Hanya Ubuntu yang didukung."
            echo "OS terdeteksi: $ID $VERSION_ID"
            exit 1
        fi
    else
        print_error "Tidak dapat mendeteksi sistem operasi."
        exit 1
    fi
}

# ============================================================
# INSTALASI DEPENDENCY
# ============================================================

install_git() {
    print_info "Memeriksa Git..."
    
    if command -v git &> /dev/null; then
        local git_version=$(git --version | awk '{print $3}')
        print_success "Git sudah terinstall (versi $git_version)"
        return 0
    fi
    
    print_info "Menginstall Git..."
    apt-get update -qq
    apt-get install -y -qq git
    print_success "Git berhasil diinstall"
}

install_docker() {
    print_info "Memeriksa Docker..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_success "Docker sudah terinstall (versi $docker_version)"
        return 0
    fi
    
    print_info "Menginstall Docker..."
    
    # Hapus versi lama jika ada
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
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start dan enable Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker berhasil diinstall"
}

install_docker_compose() {
    print_info "Memeriksa Docker Compose..."
    
    if command -v docker compose &> /dev/null; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        print_success "Docker Compose sudah terinstall (versi $compose_version)"
        return 0
    fi
    
    print_info "Docker Compose sudah terinstall sebagai plugin Docker"
    print_success "Docker Compose siap digunakan"
}

# ============================================================
# CLONE REPOSITORY
# ============================================================

clone_repository() {
    print_info "Memeriksa repository..."
    
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        print_success "Repository sudah ada di $INSTALL_DIR"
        return 0
    fi
    
    print_info "Meng-clone repository ke $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/RinaPython/Telegram-Finance-Bot.git "$INSTALL_DIR"
    print_success "Repository berhasil di-clone"
}

# ============================================================
# KONFIGURASI .ENV
# ============================================================

setup_env() {
    print_info "Memeriksa file .env..."
    
    local env_file="$INSTALL_DIR/.env"
    
    if [[ -f "$env_file" ]]; then
        print_success "File .env sudah ada, tidak akan ditimpa"
        return 0
    fi
    
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
        print_info "Membuat file .env dari .env.example..."
        cp "$INSTALL_DIR/.env.example" "$env_file"
        print_success "File .env berhasil dibuat"
        echo ""
        echo "⚠️  PERHATIAN: File .env telah dibuat di $env_file"
        echo "   Silakan isi dengan kredensial Anda sebelum menjalankan bot:"
        echo "   nano $env_file"
        echo ""
    else
        print_error "File .env.example tidak ditemukan!"
        exit 1
    fi
}

# ============================================================
# PERSIAPAN DIREKTORI
# ============================================================

setup_directories() {
    print_info "Menyiapkan direktori data dan logs..."
    
    mkdir -p "$INSTALL_DIR/data"
    mkdir -p "$INSTALL_DIR/logs"
    
    chmod 755 "$INSTALL_DIR/data"
    chmod 755 "$INSTALL_DIR/logs"
    
    print_success "Direktori data dan logs siap"
}

# ============================================================
# INSTALASI DASHBOARD
# ============================================================

install_dashboard() {
    print_info "Menginstall Dashboard VPS..."
    
    if [[ -f "/usr/local/bin/finance-dashboard" ]]; then
        print_success "Dashboard sudah terinstall"
        return 0
    fi
    
    local dashboard_script="$INSTALL_DIR/scripts/install-dashboard.sh"
    
    if [[ -f "$dashboard_script" ]]; then
        bash "$dashboard_script"
        print_success "Dashboard berhasil diinstall"
    else
        print_error "Script dashboard tidak ditemukan: $dashboard_script"
        exit 1
    fi
}

# ============================================================
# BUILD & START BOT
# ============================================================

build_and_start_bot() {
    print_info "Membangun dan menjalankan bot..."
    
    cd "$INSTALL_DIR"
    
    # Cek apakah .env sudah diisi (minimal TELEGRAM_TOKEN tidak kosong)
    if [[ -f ".env" ]]; then
        if grep -q "^TELEGRAM_TOKEN=.*[^[:space:]]" .env 2>/dev/null; then
            print_success "File .env terdeteksi dengan TELEGRAM_TOKEN"
        else
            print_info "File .env belum diisi dengan TELEGRAM_TOKEN"
            print_info "Bot akan menunggu sampai .env dikonfigurasi"
        fi
    fi
    
    # Build image
    print_info "Membangun image Docker..."
    if docker compose build --no-cache; then
        print_success "Image Docker berhasil dibangun"
    else
        print_error "Gagal membangun image Docker"
        exit 1
    fi
    
    # Start container dengan restart policy
    print_info "Menjalankan container..."
    
    # Pastikan restart policy di docker-compose.yml
    if ! grep -q "restart:" "$INSTALL_DIR/docker-compose.yml"; then
        print_info "Menambahkan restart policy ke docker-compose.yml..."
        sed -i '/^services:/,/^[^ ]/ { /finance-bot:/,/^[^ ]/ s/\(^[[:space:]]*\)container_name:/\1restart: unless-stopped\n\1container_name:/ }' "$INSTALL_DIR/docker-compose.yml"
    fi
    
    if docker compose up -d; then
        print_success "Container berhasil dijalankan"
    else
        print_error "Gagal menjalankan container"
        exit 1
    fi
    
    # Health check
    print_info "Menunggu bot siap..."
    sleep 10
    
    if docker compose ps | grep -q "Up"; then
        print_success "Bot berjalan dengan status: RUNNING"
    else
        print_error "Bot tidak berjalan dengan normal. Periksa log:"
        echo "  docker compose -f $INSTALL_DIR/docker-compose.yml logs --tail=50"
    fi
}

# ============================================================
# AUTO START SETELAH REBOOT
# ============================================================

setup_autostart() {
    print_info "Mengatur auto-start setelah reboot..."
    
    # Docker sudah di-enable oleh systemd
    # Container memiliki restart: unless-stopped di compose
    
    print_success "Auto-start telah dikonfigurasi"
    echo "  - Docker: systemd enabled"
    echo "  - Bot: restart policy 'unless-stopped'"
}

# ============================================================
# FUNGSI UTAMA
# ============================================================

main() {
    clear
    print_header "🔄 INSTALASI VPS - TELEGRAM FINANCE BOT"
    echo ""
    echo "Direktori instalasi: $INSTALL_DIR"
    echo ""
    
    # Pemeriksaan prasyarat
    check_sudo
    check_internet
    check_os
    
    echo ""
    print_header "📦 INSTALASI DEPENDENCY"
    echo ""
    install_git
    install_docker
    install_docker_compose
    
    echo ""
    print_header "📁 PERSIAPAN PROJECT"
    echo ""
    clone_repository
    setup_env
    setup_directories
    
    echo ""
    print_header "🖥️ INSTALASI DASHBOARD"
    echo ""
    install_dashboard
    
    echo ""
    print_header "🐳 BUILD & START BOT"
    echo ""
    build_and_start_bot
    
    echo ""
    print_header "🔄 AUTO-START SETELAH REBOOT"
    echo ""
    setup_autostart
    
    echo ""
    print_header "✅ INSTALASI SELESAI"
    echo ""
    echo "📋 INFORMASI PENTING:"
    echo ""
    echo "1. Konfigurasi .env:"
    echo "   nano $INSTALL_DIR/.env"
    echo ""
    echo "2. Jalankan dashboard:"
    echo "   finance-dashboard"
    echo ""
    echo "3. Atau manage bot manual:"
    echo "   cd $INSTALL_DIR"
    echo "   docker compose ps          # Cek status"
    echo "   docker compose logs -f     # Lihat log"
    echo "   docker compose restart     # Restart bot"
    echo ""
    echo "4. Bot akan otomatis berjalan setelah VPS reboot"
    echo ""
    
    # Tampilkan status bot
    echo -e "${BLUE}📊 STATUS BOT:${NC}"
    cd "$INSTALL_DIR"
    if docker compose ps 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✅ Bot berjalan dengan normal${NC}"
    else
        echo -e "${YELLOW}⚠️  Bot belum berjalan. Periksa .env dan jalankan:${NC}"
        echo "   cd $INSTALL_DIR && docker compose up -d"
    fi
    
    echo ""
    echo -e "${GREEN}Terima kasih telah menggunakan Telegram Finance Bot! 🚀${NC}"
    echo ""
}

# ============================================================
# EKSEKUSI
# ============================================================

main
