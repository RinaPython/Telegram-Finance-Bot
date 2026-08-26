#!/usr/bin/env bash

# ============================================================
# TELEGRAM FINANCE BOT - BOOTSTRAP INSTALLER
# ============================================================
# Fungsi:
#   - Install Git jika belum ada
#   - Clone repository
#   - Menjalankan install-vps.sh
#
# Jalankan:
#   curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/scripts/bootstrap.sh | sudo bash
# ============================================================

set -Eeuo pipefail

REPO_URL="https://github.com/RinaPython/Telegram-Finance-Bot.git"
PROJECT_NAME="Telegram-Finance-Bot"
INSTALL_DIR="/opt/${PROJECT_NAME}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

banner() {
    clear 2>/dev/null || true

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              💰 TELEGRAM FINANCE BOT                        ║"
    echo "║                  VPS INSTALLER                              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${WHITE}${BOLD}Automatic VPS Installation${NC}"
    echo ""
}

check_root() {
    if [ "${EUID}" -ne 0 ]; then
        error "Script harus dijalankan sebagai root."
        echo ""
        echo "Gunakan:"
        echo "sudo bash"
        exit 1
    fi

    success "Hak akses root: OK"
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        error "Tidak dapat mendeteksi sistem operasi."
        exit 1
    fi

    . /etc/os-release

    echo ""
    info "Sistem operasi: ${PRETTY_NAME}"

    case "${ID}" in
        ubuntu|debian)
            success "OS didukung"
            ;;
        *)
            warning "OS ${ID} belum diuji secara khusus."
            warning "Installer akan tetap mencoba melanjutkan."
            ;;
    esac
}

check_internet() {
    info "Memeriksa koneksi internet..."

    if curl -fsS --connect-timeout 10 https://github.com >/dev/null; then
        success "Koneksi internet: OK"
    else
        error "Tidak dapat terhubung ke GitHub."
        exit 1
    fi
}

install_git() {
    if command -v git >/dev/null 2>&1; then
        success "Git sudah terinstall: $(git --version)"
        return
    fi

    info "Git belum terinstall. Menginstall Git..."

    export DEBIAN_FRONTEND=noninteractive

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y git
    else
        error "Package manager apt-get tidak ditemukan."
        exit 1
    fi

    success "Git berhasil diinstall"
}

clone_repository() {

    echo ""
    info "Menyiapkan repository..."

    if [ -d "${INSTALL_DIR}/.git" ]; then
        success "Repository sudah ada di:"
        echo "  ${INSTALL_DIR}"

        cd "${INSTALL_DIR}"

        info "Mengambil perubahan terbaru dari GitHub..."

        git fetch origin
        git reset --hard origin/main

        success "Repository berhasil diperbarui."

    elif [ -d "${INSTALL_DIR}" ] && [ "$(ls -A "${INSTALL_DIR}" 2>/dev/null)" ]; then

        error "Folder ${INSTALL_DIR} sudah ada dan tidak kosong."
        echo ""
        echo "Installer tidak akan menghapus data secara otomatis."
        echo ""
        echo "Jika folder tersebut memang tidak diperlukan,"
        echo "hapus/rename secara manual lalu jalankan kembali."
        exit 1

    else

        info "Clone repository dari GitHub..."

        mkdir -p "$(dirname "${INSTALL_DIR}")"

        git clone --branch main "${REPO_URL}" "${INSTALL_DIR}"

        success "Repository berhasil di-clone."

    fi
}

verify_repository() {

    cd "${INSTALL_DIR}"

    echo ""
    info "Memeriksa struktur project..."

    REQUIRED_FILES=(
        ".env.example"
        "Dockerfile"
        "docker-compose.yml"
        "requirements.txt"
        "scripts/install-vps.sh"
        "scripts/install-dashboard.sh"
    )

    for FILE in "${REQUIRED_FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            success "${FILE}"
        else
            error "File tidak ditemukan: ${FILE}"
            exit 1
        fi
    done

    success "Struktur repository valid."
}

prepare_permissions() {

    cd "${INSTALL_DIR}"

    chmod +x scripts/*.sh 2>/dev/null || true

    success "Permission script diperbaiki."
}

run_installer() {

    cd "${INSTALL_DIR}"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}${BOLD}MENJALANKAN INSTALLER VPS${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    bash scripts/install-vps.sh
}

show_final_info() {

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${WHITE}${BOLD}          TELEGRAM FINANCE BOT SIAP! 🚀${NC}                 ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${WHITE}Project:${NC}"
    echo "  ${INSTALL_DIR}"
    echo ""

    echo -e "${WHITE}Dashboard:${NC}"
    echo "  finance-dashboard"
    echo ""

    echo -e "${WHITE}Melihat status:${NC}"
    echo "  cd ${INSTALL_DIR}"
    echo "  docker compose ps"
    echo ""

    echo -e "${WHITE}Melihat log:${NC}"
    echo "  cd ${INSTALL_DIR}"
    echo "  docker compose logs -f"
    echo ""

    echo -e "${WHITE}Restart bot:${NC}"
    echo "  cd ${INSTALL_DIR}"
    echo "  docker compose restart"
    echo ""
}

main() {

    banner

    check_root
    check_os
    check_internet
    install_git
    clone_repository
    verify_repository
    prepare_permissions
    run_installer
    show_final_info
}

main "$@"
