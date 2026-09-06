#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - INSTALL DOCKER v2.0
# ============================================================
# Memeriksa dan menginstall Docker + Docker Compose
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# 1. CEK APAKAH DOCKER SUDAH TERINSTALL
# ============================================================
if command -v docker &> /dev/null; then
    print_success "Docker sudah terinstall."
    docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
    print_info "Versi Docker: $docker_version"
    
    # --- Pastikan Docker daemon berjalan ---
    print_info "Memeriksa Docker daemon..."
    if systemctl is-active --quiet docker; then
        print_success "Docker daemon sedang berjalan."
    else
        print_warning "Docker daemon tidak berjalan. Mencoba menjalankan..."
        systemctl start docker
        sleep 2
        if systemctl is-active --quiet docker; then
            print_success "Docker daemon berhasil dijalankan."
        else
            print_error "Gagal menjalankan Docker daemon."
            echo ""
            echo "Coba periksa status: systemctl status docker"
            echo "Atau mulai manual: systemctl start docker"
            exit 1
        fi
    fi
    
    # --- Pastikan Docker enabled saat boot ---
    if systemctl is-enabled docker &> /dev/null; then
        print_success "Docker enabled saat boot."
    else
        print_info "Mengaktifkan Docker saat boot..."
        systemctl enable docker
        print_success "Docker enabled saat boot."
    fi
    
    # --- Cek Docker Compose ---
    print_info "Memeriksa Docker Compose..."
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version 2>/dev/null | cut -d' ' -f4 | sed 's/,//')
        print_success "Docker Compose tersedia (versi $compose_version)"
    else
        print_warning "Docker Compose tidak ditemukan."
        print_info "Menginstall Docker Compose plugin..."
        apt-get update -qq
        if apt-get install -y -qq docker-compose-plugin; then
            print_success "Docker Compose plugin berhasil diinstall."
        else
            print_error "Gagal menginstall Docker Compose plugin."
            exit 1
        fi
    fi
    
    print_success "✅ Docker sudah siap digunakan."
    exit 0
fi

# ============================================================
# 2. INSTALL DOCKER (JIKA BELUM ADA)
# ============================================================
print_info "Docker tidak ditemukan. Memulai instalasi..."

# --- Hapus paket lama jika ada (aman) ---
print_info "Membersihkan paket Docker lama jika ada..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# --- Install prerequisite ---
print_info "Menginstall prerequisite..."
apt-get update -qq
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# --- Tambahkan GPG key Docker ---
print_info "Menambahkan GPG key Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# --- Tambahkan repository Docker ---
print_info "Menambahkan repository Docker..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# --- Install Docker ---
print_info "Menginstall Docker..."
apt-get update -qq
apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# --- Start dan enable Docker ---
print_info "Menjalankan dan mengaktifkan Docker..."
systemctl start docker
systemctl enable docker

# --- Verifikasi instalasi ---
print_info "Memverifikasi instalasi Docker..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
    print_success "Docker berhasil diinstall. Versi: $docker_version"
    
    if systemctl is-active --quiet docker; then
        print_success "Docker daemon berjalan."
    else
        print_error "Docker daemon tidak berjalan setelah instalasi."
        exit 1
    fi
else
    print_error "Gagal menginstall Docker."
    exit 1
fi

# --- Verifikasi Docker Compose ---
print_info "Memverifikasi Docker Compose..."
if docker compose version &> /dev/null; then
    compose_version=$(docker compose version 2>/dev/null | cut -d' ' -f4 | sed 's/,//')
    print_success "Docker Compose tersedia (versi $compose_version)"
else
    print_warning "Docker Compose plugin tidak ditemukan."
    print_info "Menginstall Docker Compose plugin..."
    apt-get install -y -qq docker-compose-plugin
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version 2>/dev/null | cut -d' ' -f4 | sed 's/,//')
        print_success "Docker Compose berhasil diinstall (versi $compose_version)"
    else
        print_error "Gagal menginstall Docker Compose plugin."
        exit 1
    fi
fi

# ============================================================
# 3. SELESAI
# ============================================================
echo ""
print_success "✅ Docker dan Docker Compose berhasil diinstall."
echo ""
echo "📋 Ringkasan Docker:"
echo "  - Docker: $(docker --version)"
echo "  - Docker Compose: $(docker compose version 2>/dev/null | head -n1)"
echo "  - Service: $(systemctl is-active docker) (enabled: $(systemctl is-enabled docker))"