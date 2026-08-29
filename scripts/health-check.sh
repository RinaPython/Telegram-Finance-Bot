#!/bin/bash
# ============================================================
# TELEGRAM FINANCE BOT - HEALTH CHECK v2.0
# ============================================================

set -Eeuo pipefail

# ============================================================
# KONFIGURASI
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
CONTAINER_NAME="finance-bot"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# FUNGSI
# ============================================================

check_docker() {
    if ! systemctl is-active --quiet docker 2>/dev/null; then
        echo -e "${RED}✗ Docker: TIDAK BERJALAN${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Docker: BERJALAN${NC}"
    return 0
}

check_container() {
    if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        echo -e "${GREEN}✓ Container: $CONTAINER_NAME ($status)${NC}"
        
        if [[ "$health" == "healthy" ]]; then
            echo -e "${GREEN}✓ Health: SEHAT${NC}"
            return 0
        elif [[ "$health" == "unhealthy" ]]; then
            echo -e "${RED}✗ Health: TIDAK SEHAT${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠ Health: $health${NC}"
            return 0
        fi
    fi
    echo -e "${YELLOW}⚠ Container: TIDAK BERJALAN${NC}"
    return 1
}

check_env() {
    local env_file="$INSTALL_DIR/.env"
    if [[ ! -f "$env_file" ]]; then
        echo -e "${YELLOW}⚠ .env: TIDAK DITEMUKAN${NC}"
        return 1
    fi
    
    set -a
    # shellcheck source=/dev/null
    source "$env_file"
    set +a
    
    local missing=()
    for var in TELEGRAM_TOKEN AUTHORIZED_USER_ID GEMINI_API_KEY; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ .env: LENGKAP${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ .env: BELUM LENGKAP (${missing[*]})${NC}"
        return 1
    fi
}

check_restart_policy() {
    local policy=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$CONTAINER_NAME" 2>/dev/null)
    if [[ "$policy" == "unless-stopped" ]]; then
        echo -e "${GREEN}✓ Restart Policy: unless-stopped${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Restart Policy: $policy${NC}"
        return 1
    fi
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo "=== HEALTH CHECK: Telegram Finance Bot ==="
    echo ""
    
    local status=0
    check_docker || status=1
    check_env || status=1
    check_container || status=1
    check_restart_policy || status=1
    
    echo ""
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}✅ SEMUA SISTEM SEHAT${NC}"
    else
        echo -e "${YELLOW}⚠ BEBERAPA KOMPONEN BERMASALAH${NC}"
        echo "Periksa log: docker compose -f $INSTALL_DIR/docker-compose.yml logs --tail=50"
    fi
    
    exit $status
}

main
