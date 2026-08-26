#!/bin/bash

# ============================================================
# FINANCE BOT — VPS INSTALLER
# Version: 1.0.0
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/install.log"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date) [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "$(date) [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "$(date) [WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "$(date) [ERROR] $1" >> "$LOG_FILE"
}

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "    ███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗"
    echo "    ██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝"
    echo "    █████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║  ███╗█████╗"
    echo "    ██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║   ██║██╔══╝"
    echo "    ██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╔╝███████╗"
    echo "    ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "${WHITE}💰 PERSONAL FINANCE TRACKER${NC}"
    echo ""
}

check_system() {
    log_info "Memeriksa sistem..."
    
    OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown")
    log_info "OS: $OS"
    
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_GB=$((RAM_TOTAL / 1024))
    if [ $RAM_GB -lt 1 ]; then
        log_warning "RAM: ${RAM_GB}GB (direkomendasikan: 1GB+)"
    else
        log_success "RAM: ${RAM_GB}GB"
    fi
    
    DISK_AVAIL=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_AVAIL -lt 5 ]; then
        log_warning "Disk space: ${DISK_AVAIL}GB available (direkomendasikan: 5GB+)"
    else
        log_success "Disk space: ${DISK_AVAIL}GB available"
    fi
    
    log_info "Memeriksa koneksi internet..."
    if curl -s -o /dev/null -w "%{http_code}" https://api.telegram.org | grep -q "200"; then
        log_success "Koneksi internet: OK"
    else
        log_error "Koneksi internet: GAGAL"
        exit 1
    fi
}

install_docker() {
    log_info "Memeriksa Docker..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        log_success "Docker sudah terinstall: v$DOCKER_VERSION"
    else
        log_info "Menginstal Docker..."
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sh /tmp/get-docker.sh
        rm /tmp/get-docker.sh
        systemctl enable docker
        systemctl start docker
        log_success "Docker terinstall"
    fi
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | sed 's/,//')
        log_success "Docker Compose terinstall: v$COMPOSE_VERSION"
    elif docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | cut -d' ' -f3 | sed 's/,//')
        log_success "Docker Compose terinstall: v$COMPOSE_VERSION"
    else
        log_info "Menginstal Docker Compose..."
        COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d'"' -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose terinstall"
    fi
}

setup_project() {
    log_info "Menyiapkan project..."
    
    mkdir -p "$PROJECT_DIR/data" "$PROJECT_DIR/logs"
    chmod 755 "$PROJECT_DIR/data" "$PROJECT_DIR/logs"
    
    touch "$PROJECT_DIR/data/.gitkeep"
    
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        if [ -f "$PROJECT_DIR/.env.example" ]; then
            cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
            log_success ".env dibuat dari .env.example"
            echo ""
            echo -e "${YELLOW}⚠️  Edit .env dengan credentials Anda:${NC}"
            echo -e "  ${BLUE}nano .env${NC}"
            echo ""
        else
            log_error ".env.example tidak ditemukan!"
            exit 1
        fi
    else
        log_success ".env sudah ada"
    fi
    
    chmod 600 "$PROJECT_DIR/.env"
}

install_dashboard() {
    log_info "Memasang dashboard..."
    
    if [ -f "$PROJECT_DIR/scripts/install-dashboard.sh" ]; then
        bash "$PROJECT_DIR/scripts/install-dashboard.sh"
    else
        log_warning "install-dashboard.sh tidak ditemukan, melewati..."
    fi
}

build_and_deploy() {
    log_info "Membangun Docker image..."
    cd "$PROJECT_DIR"
    
    if docker compose build --no-cache 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Docker build selesai"
    else
        log_error "Docker build gagal"
        exit 1
    fi
    
    log_info "Menjalankan container..."
    if docker compose up -d 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Container berjalan"
    else
        log_error "Gagal menjalankan container"
        exit 1
    fi
}

health_check() {
    log_info "Melakukan health check..."
    sleep 10
    
    if docker ps --format "{{.Names}}" | grep -q "finance-bot"; then
        log_success "Container berjalan"
        
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' finance-bot 2>/dev/null)
        if [ "$HEALTH" = "healthy" ]; then
            log_success "Health status: HEALTHY"
        else
            log_warning "Health status: $HEALTH (menunggu...)"
        fi
    else
        log_error "Container tidak berjalan"
        exit 1
    fi
}

show_results() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}${BOLD}              DEPLOYMENT COMPLETE ✅${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}[✓]${NC} Docker: ${WHITE}$(docker --version 2>/dev/null | head -1)${NC}"
    echo -e "${GREEN}[✓]${NC} Docker Compose: ${WHITE}$(docker-compose --version 2>/dev/null || echo "terinstall")${NC}"
    echo -e "${GREEN}[✓]${NC} Container: ${WHITE}$(docker ps --format "{{.Names}}" --filter "name=finance-bot" 2>/dev/null || echo "N/A")${NC}"
    echo -e "${GREEN}[✓]${NC} Bot: ${WHITE}$(docker ps --format "{{.Status}}" --filter "name=finance-bot" 2>/dev/null || echo "N/A")${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📋 ${BOLD}COMMANDS${NC}"
    echo ""
    echo -e "  ${BLUE}finance-dashboard${NC}   - Buka dashboard management"
    echo -e "  ${BLUE}docker compose logs -f${NC}  - Lihat log real-time"
    echo -e "  ${BLUE}docker compose restart${NC}  - Restart bot"
    echo -e "  ${BLUE}docker compose down${NC}     - Stop bot"
    echo -e "  ${BLUE}docker compose up -d${NC}    - Start bot"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}BOT SIAP DIGUNAKAN!${NC} 🚀"
    echo ""
}

main() {
    print_banner
    
    log_info "Memulai instalasi pada $(date)"
    
    check_system
    install_docker
    setup_project
    
    echo ""
    echo -e "${YELLOW}⚠️  Pastikan .env sudah dikonfigurasi dengan credentials Anda${NC}"
    echo -e "${WHITE}  Edit: ${BLUE}nano .env${NC}"
    echo ""
    echo -ne "${WHITE}Lanjutkan instalasi? [y/N]: ${NC}"
    read confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Instalasi dibatalkan"
        exit 0
    fi
    
    install_dashboard
    build_and_deploy
    health_check
    show_results
    
    log_info "Instalasi selesai pada $(date)"
}

main "$@"