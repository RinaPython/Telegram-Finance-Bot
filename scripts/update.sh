#!/bin/bash

# ============================================================
# FINANCE BOT — UPDATE SCRIPT
# Version: 1.0.0
# ============================================================

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
cd "$PROJECT_DIR" || exit 1

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}          FINANCE BOT — UPDATE${NC}${CYAN}                               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
    print_header
    
    log_info "Memeriksa update dari GitHub..."
    
    if ! git diff --quiet; then
        log_warning "Ada perubahan lokal yang belum di-commit"
        echo -ne "${WHITE}Lanjutkan update? (perubahan lokal akan hilang) [y/N]: ${NC}"
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Update dibatalkan"
            exit 0
        fi
    fi
    
    log_info "Mengambil update dari GitHub..."
    if git pull; then
        log_success "Git pull berhasil"
    else
        log_error "Git pull gagal"
        exit 1
    fi
    
    log_info "Membangun ulang Docker image..."
    if docker compose build --no-cache 2>&1 | tail -20; then
        log_success "Docker build berhasil"
    else
        log_error "Docker build gagal"
        exit 1
    fi
    
    log_info "Merestart container..."
    docker compose down
    docker compose up -d
    
    log_info "Menunggu container siap..."
    sleep 10
    
    if docker ps --format "{{.Names}}" | grep -q "finance-bot"; then
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' finance-bot 2>/dev/null)
        if [ "$HEALTH" = "healthy" ]; then
            log_success "Container sehat: HEALTHY"
        else
            log_warning "Health status: $HEALTH"
        fi
    else
        log_error "Container tidak berjalan"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ Update selesai!${NC}"
    echo ""
    echo -e "${WHITE}📋 Log terakhir:${NC}"
    docker compose logs --tail=10
    echo ""
}

main "$@"