#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - CHECK SYSTEM v2.0
# ============================================================
# Memeriksa: OS, root, CPU, RAM, disk, internet, dependency
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# 1. CEK HAK AKSES ROOT/SUDO
# ============================================================
print_info "Memeriksa hak akses root/sudo..."
if [[ $EUID -ne 0 ]]; then
    print_error "Script ini HARUS dijalankan dengan sudo atau sebagai root."
    exit 1
fi
print_success "Hak akses root/sudo terkonfirmasi."

# ============================================================
# 2. CEK SISTEM OPERASI (HANYA UBUNTU 22.04/24.04)
# ============================================================
print_info "Memeriksa sistem operasi..."
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "Hanya Ubuntu yang didukung. Terdeteksi: $ID"
        exit 1
    fi
    
    if [[ "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ]]; then
        print_success "OS: Ubuntu $VERSION_ID (DIDUKUNG)"
    else
        print_error "Versi Ubuntu $VERSION_ID TIDAK didukung. Gunakan Ubuntu 22.04 atau 24.04."
        exit 1
    fi
else
    print_error "Tidak dapat mendeteksi OS."
    exit 1
fi

# ============================================================
# 3. CEK ARSITEKTUR CPU (x86_64 / aarch64)
# ============================================================
print_info "Memeriksa arsitektur CPU..."
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
    print_success "Arsitektur: x86_64 (AMD64) - DIDUKUNG"
elif [[ "$arch" == "aarch64" ]]; then
    print_success "Arsitektur: aarch64 (ARM64) - DIDUKUNG"
else
    print_error "Arsitektur $arch TIDAK didukung. Hanya x86_64 dan aarch64."
    exit 1
fi

# ============================================================
# 4. CEK RAM (MINIMAL 1GB)
# ============================================================
print_info "Memeriksa RAM..."
ram_total=$(free -m | awk '/Mem:/ {print $2}')
if [[ $ram_total -lt 1024 ]]; then
    print_error "RAM minimal 1GB. Terdeteksi: ${ram_total}MB"
    exit 1
fi
print_success "RAM: ${ram_total}MB (≥ 1GB)"

# ============================================================
# 5. CEK RUANG DISK (MINIMAL 2GB)
# ============================================================
print_info "Memeriksa ruang disk..."
disk_available=$(df -m / | awk 'NR==2 {print $4}')
if [[ $disk_available -lt 2048 ]]; then
    print_error "Ruang disk minimal 2GB. Tersedia: ${disk_available}MB"
    exit 1
fi
print_success "Ruang disk tersedia: ${disk_available}MB (≥ 2GB)"

# ============================================================
# 6. CEK KONEKSI INTERNET (HTTPS)
# ============================================================
print_info "Memeriksa koneksi internet (HTTPS)..."
test_urls=(
    "https://github.com"
    "https://raw.githubusercontent.com"
    "https://api.github.com"
    "https://registry-1.docker.io"
    "https://www.google.com"
)

connected=false
for url in "${test_urls[@]}"; do
    if curl -4 -sSf --connect-timeout 5 --max-time 10 -o /dev/null "$url" 2>/dev/null; then
        connected=true
        break
    fi
done

if [[ "$connected" == false ]]; then
    print_error "Tidak ada koneksi internet (HTTPS). Periksa DNS, firewall, atau proxy."
    echo ""
    echo "Diagnostik:"
    echo "  - Cek DNS: getent hosts github.com"
    echo "  - Cek firewall: ufw status"
    echo "  - Cek proxy: env | grep -i proxy"
    exit 1
fi
print_success "Koneksi internet (HTTPS) OK"

# ============================================================
# 7. CEK DEPENDENCY (curl, git, jq)
# ============================================================

# --- curl ---
print_info "Memeriksa curl..."
if command -v curl &> /dev/null; then
    curl_version=$(curl --version | head -n1 | cut -d' ' -f2)
    print_success "curl tersedia (versi $curl_version)"
else
    print_info "curl tidak ditemukan, mencoba menginstall..."
    apt-get update -qq
    if apt-get install -y -qq curl; then
        print_success "curl berhasil diinstall."
    else
        print_error "Gagal menginstall curl. Silakan install secara manual."
        exit 1
    fi
fi

# --- git ---
print_info "Memeriksa git..."
if command -v git &> /dev/null; then
    git_version=$(git --version | cut -d' ' -f3)
    print_success "git tersedia (versi $git_version)"
else
    print_info "git tidak ditemukan, mencoba menginstall..."
    apt-get update -qq
    if apt-get install -y -qq git; then
        print_success "git berhasil diinstall."
    else
        print_error "Gagal menginstall git. Silakan install secara manual."
        exit 1
    fi
fi

# --- jq ---
print_info "Memeriksa jq..."
if command -v jq &> /dev/null; then
    jq_version=$(jq --version 2>/dev/null | cut -d'-' -f2)
    print_success "jq tersedia (versi $jq_version)"
else
    print_info "jq tidak ditemukan, mencoba menginstall..."
    apt-get update -qq
    if apt-get install -y -qq jq; then
        print_success "jq berhasil diinstall."
    else
        print_warning "Gagal menginstall jq. Beberapa fitur dashboard mungkin tidak berjalan."
        print_info "Untuk menginstall manual: apt-get install jq -y"
        # Tidak exit 1 karena jq hanya untuk dashboard, bukan untuk bot
    fi
fi

# ============================================================
# 8. SELESAI
# ============================================================
echo ""
print_success "Semua pemeriksaan sistem BERHASIL."
echo ""
echo "📋 Ringkasan VPS:"
echo "  - OS: Ubuntu $VERSION_ID ($arch)"
echo "  - RAM: ${ram_total}MB"
echo "  - Disk: ${disk_available}MB tersedia"
echo "  - Internet: OK (HTTPS)"
echo "  - Dependency: curl ✓, git ✓, jq ✓"