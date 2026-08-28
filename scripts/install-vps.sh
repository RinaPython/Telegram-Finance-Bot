#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - INSTALASI VPS v2.0
# ============================================================

set -Eeuo pipefail

INSTALL_DIR="/opt/Telegram-Finance-Bot"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "${BLUE}============================================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}============================================================${NC}"; }
print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }

# ============================================================
# PRASYARAT
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
    exit 1
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "OS: Ubuntu $VERSION_ID"
        else
            print_error "Hanya Ubuntu yang didukung"
            exit 1
        fi
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
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
    print_success "Docker berhasil diinstall"
}

# ============================================================
# SETUP PROJECT
# ============================================================

setup_project() {
    print_info "Menyiapkan project di $INSTALL_DIR..."
    
    # Clone jika belum ada
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone https://github.com/RinaPython/Telegram-Finance-Bot.git "$INSTALL_DIR"
        print_success "Repository berhasil di-clone"
    else
        cd "$INSTALL_DIR"
        git pull --ff-only 2>/dev/null || true
        print_success "Repository sudah ada, diperbarui"
    fi
    
    # Setup .env jika belum ada
    if [[ ! -f "$INSTALL_DIR/.env" ]]; then
        cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
        print_success "File .env dibuat dari .env.example"
        print_warning "⚠️  .env masih kosong, isi dengan kredensial Anda"
    else
        print_success "File .env sudah ada"
    fi
    
    # Setup direktori
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
    if [[ -f "$INSTALL_DIR/scripts/install-dashboard.sh" ]]; then
        bash "$INSTALL_DIR/scripts/install-dashboard.sh"
        print_success "Dashboard berhasil diinstall"
    else
        print_error "File install-dashboard.sh tidak ditemukan"
        exit 1
    fi
}

# ============================================================
# SETUP AUTO-START
# ============================================================

setup_autostart() {
    print_info "Mengatur auto-start..."
    
    # Pastikan Docker aktif setelah reboot
    systemctl enable docker 2>/dev/null || true
    
    # Tambahkan restart policy ke docker-compose.yml jika belum ada
    local compose_file="$INSTALL_DIR/docker-compose.yml"
    if [[ -f "$compose_file" ]] && ! grep -q "restart:" "$compose_file"; then
        sed -i '/^services:/,/^[^ ]/ { /finance-bot:/,/^[^ ]/ s/\(^[[:space:]]*\)container_name:/\1restart: unless-stopped\n\1container_name:/ }' "$compose_file"
        print_success "Restart policy ditambahkan ke docker-compose.yml"
    fi
    
    print_success "Auto-start telah dikonfigurasi"
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
    setup_project

    echo ""
    print_header "🖥️ INSTALASI DASHBOARD"
    install_dashboard

    echo ""
    print_header "🔄 AUTO-START"
    setup_autostart

    echo ""
    print_header "✅ INSTALASI VPS SELESAI"
    echo ""
    echo -e "${GREEN}Dashboard:${NC} finance-dashboard"
    echo -e "${GREEN}Direktori:${NC} $INSTALL_DIR"
    echo -e "${GREEN}.env:${NC} $INSTALL_DIR/.env"
    echo ""
}

# ============================================================
# EKSEKUSI
# ============================================================

main
