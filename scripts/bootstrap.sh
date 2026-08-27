#!/usr/bin/env bash

# ============================================================
# Telegram Finance Bot
# Automatic VPS Bootstrap Installer
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

REPO_URL="https://github.com/RinaPython/Telegram-Finance-Bot.git"
BRANCH="main"
PROJECT_NAME="Telegram-Finance-Bot"
INSTALL_DIR="/opt/${PROJECT_NAME}"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[ OK ]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# ------------------------------------------------------------
# Error Handler
# ------------------------------------------------------------

trap 'echo -e "\n${RED}[ERROR] Bootstrap gagal pada baris ${LINENO}.${RESET}"; exit 1' ERR

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║             💰 TELEGRAM FINANCE BOT                         ║"
echo "║                 AUTOMATIC INSTALLER                         ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo ""
echo -e "${WHITE}Repository:${RESET}"
echo "https://github.com/RinaPython/Telegram-Finance-Bot"
echo ""

# ------------------------------------------------------------
# Check Root
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    error "Script harus dijalankan sebagai root atau menggunakan sudo."
    echo ""
    echo "Gunakan:"
    echo ""
    echo "sudo bash"
    exit 1
fi

success "Root access tersedia."

# ------------------------------------------------------------
# Check OS
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "Tidak dapat mendeteksi sistem operasi."
    exit 1
fi

source /etc/os-release

echo ""
info "Sistem operasi: ${PRETTY_NAME}"

case "${ID}" in
    ubuntu|debian)
        success "Sistem operasi didukung."
        ;;
    *)
        warning "OS ${ID} belum diuji secara khusus."
        warning "Installer akan mencoba melanjutkan."
        ;;
esac

# ------------------------------------------------------------
# Check Internet
# ------------------------------------------------------------

echo ""
info "Memeriksa koneksi internet..."

if curl -fsS --connect-timeout 10 https://github.com >/dev/null; then
    success "Koneksi internet tersedia."
else
    error "Tidak dapat terhubung ke GitHub."
    exit 1
fi

# ------------------------------------------------------------
# Install Git
# ------------------------------------------------------------

echo ""
info "Memeriksa Git..."

if command -v git >/dev/null 2>&1; then
    success "Git sudah tersedia: $(git --version)"
else
    info "Git belum tersedia. Menginstall Git..."

    export DEBIAN_FRONTEND=noninteractive

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y git curl ca-certificates
    else
        error "apt-get tidak tersedia."
        exit 1
    fi

    success "Git berhasil diinstall."
fi

# ------------------------------------------------------------
# Prepare Installation Directory
# ------------------------------------------------------------

echo ""
info "Menyiapkan folder project..."

mkdir -p "$(dirname "${INSTALL_DIR}")"

# ------------------------------------------------------------
# Clone / Update Repository
# ------------------------------------------------------------

if [[ -d "${INSTALL_DIR}/.git" ]]; then

    echo ""
    info "Repository sudah tersedia."

    cd "${INSTALL_DIR}"

    CURRENT_BRANCH="$(git branch --show-current || true)"

    if [[ "${CURRENT_BRANCH}" != "${BRANCH}" ]]; then
        info "Menggunakan branch ${BRANCH}..."
        git checkout "${BRANCH}"
    fi

    info "Mengambil perubahan terbaru dari GitHub..."

    git fetch origin "${BRANCH}"
    git checkout "${BRANCH}"
    git pull --ff-only origin "${BRANCH}"

    success "Repository berhasil diperbarui."

elif [[ -d "${INSTALL_DIR}" ]] && [[ -n "$(find "${INSTALL_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then

    error "Folder berikut sudah ada dan tidak kosong:"
    echo ""
    echo "${INSTALL_DIR}"
    echo ""
    echo "Bootstrap tidak akan menghapus data secara otomatis."
    echo ""
    echo "Jika folder tersebut memang tidak diperlukan,"
    echo "hapus atau pindahkan terlebih dahulu."
    exit 1

else

    echo ""
    info "Meng-clone repository..."

    git clone \
        --branch "${BRANCH}" \
        --single-branch \
        "${REPO_URL}" \
        "${INSTALL_DIR}"

    success "Repository berhasil di-clone."
fi

cd "${INSTALL_DIR}"

# ------------------------------------------------------------
# Verify Repository
# ------------------------------------------------------------

echo ""
info "Memeriksa file project..."

REQUIRED_FILES=(
    "README.md"
    "Dockerfile"
    "docker-compose.yml"
    "requirements.txt"
    ".env.example"
    "scripts/install-vps.sh"
)

for file in "${REQUIRED_FILES[@]}"; do

    if [[ -f "${file}" ]]; then
        success "${file}"
    else
        error "File wajib tidak ditemukan: ${file}"
        exit 1
    fi

done

success "Struktur repository valid."

# ------------------------------------------------------------
# Make Scripts Executable
# ------------------------------------------------------------

echo ""
info "Menyiapkan permission script..."

if [[ -d "${INSTALL_DIR}/scripts" ]]; then
    find "${INSTALL_DIR}/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

success "Permission script selesai."

# ------------------------------------------------------------
# Check install-vps.sh
# ------------------------------------------------------------

echo ""
info "Memeriksa installer VPS..."

if [[ ! -x "${INSTALL_DIR}/scripts/install-vps.sh" ]]; then
    chmod +x "${INSTALL_DIR}/scripts/install-vps.sh"
fi

success "install-vps.sh siap digunakan."

# ------------------------------------------------------------
# Run Main VPS Installer
# ------------------------------------------------------------

echo ""
echo -e "${BLUE}============================================================${RESET}"
echo -e "${WHITE}           MENJALANKAN INSTALLER VPS UTAMA${RESET}"
echo -e "${BLUE}============================================================${RESET}"
echo ""

cd "${INSTALL_DIR}"

bash "${INSTALL_DIR}/scripts/install-vps.sh"

# ------------------------------------------------------------
# Final Verification
# ------------------------------------------------------------

echo ""
info "Memeriksa hasil instalasi..."

if command -v docker >/dev/null 2>&1; then
    success "Docker tersedia."
else
    warning "Docker tidak terdeteksi setelah instalasi."
fi

if docker compose version >/dev/null 2>&1; then
    success "Docker Compose tersedia."
else
    warning "Docker Compose tidak terdeteksi."
fi

# ------------------------------------------------------------
# Project Status
# ------------------------------------------------------------

echo ""
echo -e "${CYAN}============================================================${RESET}"
echo -e "${WHITE}                  STATUS PROJECT${RESET}"
echo -e "${CYAN}============================================================${RESET}"
echo ""

if docker compose ps >/dev/null 2>&1; then
    docker compose ps
else
    warning "Tidak dapat membaca status Docker Compose."
fi

# ------------------------------------------------------------
# Final Message
# ------------------------------------------------------------

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║             ✅ INSTALLATION SELESAI                         ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo ""
echo -e "${WHITE}Project:${RESET}"
echo "${INSTALL_DIR}"

echo ""
echo -e "${WHITE}Perintah penting:${RESET}"
echo ""

echo "  Masuk project:"
echo "  cd ${INSTALL_DIR}"
echo ""

echo "  Cek status:"
echo "  docker compose ps"
echo ""

echo "  Lihat log:"
echo "  docker compose logs -f"
echo ""

echo "  Restart bot:"
echo "  docker compose restart"
echo ""

if command -v finance-dashboard >/dev/null 2>&1; then
    echo "  Dashboard:"
    echo "  finance-dashboard"
    echo ""
fi

echo -e "${GREEN}Telegram Finance Bot siap digunakan.${RESET}"
echo ""
