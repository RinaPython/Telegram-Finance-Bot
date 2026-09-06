#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - HEALTH CHECK v3.0
# ============================================================
# Pemeriksaan komprehensif: Docker, container, health, restart policy
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
CONTAINER_NAME="finance-bot"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_fail() { echo -e "${RED}✗${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

EXIT_CODE=0

# ============================================================
# 1. CEK DOCKER DAEMON
# ============================================================
print_info "Memeriksa Docker daemon..."
if systemctl is-active --quiet docker 2>/dev/null; then
    print_ok "Docker daemon: BERJALAN"
else
    print_fail "Docker daemon: TIDAK BERJALAN"
    EXIT_CODE=1
fi

# ============================================================
# 2. CEK KEBERADAAN CONTAINER
# ============================================================
print_info "Memeriksa container $CONTAINER_NAME..."
if docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    print_ok "Container: ADA"
else
    print_fail "Container: TIDAK ADA"
    EXIT_CODE=1
    # Tidak perlu lanjut jika container tidak ada
    exit $EXIT_CODE
fi

# ============================================================
# 3. CEK STATUS CONTAINER
# ============================================================
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
CONTAINER_RUNNING=false

print_info "Memeriksa status container..."
case "$CONTAINER_STATUS" in
    "running")
        print_ok "Status: RUNNING"
        CONTAINER_RUNNING=true
        ;;
    "exited")
        print_fail "Status: EXITED (container berhenti)"
        EXIT_CODE=1
        ;;
    "created")
        print_warn "Status: CREATED (belum dijalankan)"
        EXIT_CODE=1
        ;;
    *)
        print_fail "Status: $CONTAINER_STATUS (tidak dikenal)"
        EXIT_CODE=1
        ;;
esac

# ============================================================
# 4. CEK HEALTH STATUS (HANYA JIKA RUNNING)
# ============================================================
if [[ "$CONTAINER_RUNNING" == true ]]; then
    print_info "Memeriksa health status..."
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)
    
    case "$HEALTH_STATUS" in
        "healthy")
            print_ok "Health: SEHAT (healthy)"
            ;;
        "unhealthy")
            print_fail "Health: TIDAK SEHAT (unhealthy)"
            EXIT_CODE=1
            ;;
        "starting")
            print_warn "Health: STARTING (masih dalam proses startup)"
            EXIT_CODE=1
            ;;
        "none"|"")
            print_warn "Health: TIDAK DIKONFIGURASI (none)"
            print_info "  Container berjalan tanpa healthcheck bawaan."
            print_info "  Bot mungkin tetap berfungsi normal."
            # Tidak dianggap error, tapi warning
            ;;
        *)
            print_warn "Health: $HEALTH_STATUS (tidak dikenal)"
            ;;
    esac
fi

# ============================================================
# 5. CEK RESTART POLICY
# ============================================================
print_info "Memeriksa restart policy..."
RESTART_POLICY=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$CONTAINER_NAME" 2>/dev/null)

case "$RESTART_POLICY" in
    "unless-stopped")
        print_ok "Restart Policy: unless-stopped (sesuai)"
        ;;
    "always")
        print_ok "Restart Policy: always (berfungsi)"
        ;;
    "on-failure")
        print_ok "Restart Policy: on-failure (berfungsi)"
        ;;
    "no"|"")
        print_warn "Restart Policy: TIDAK DIKONFIGURASI"
        print_info "  Bot tidak akan restart otomatis setelah VPS reboot."
        EXIT_CODE=1
        ;;
    *)
        print_warn "Restart Policy: $RESTART_POLICY (tidak standar)"
        ;;
esac

# ============================================================
# 6. CEK FILE .ENV
# ============================================================
print_info "Memeriksa file .env..."
if [[ -f "$INSTALL_DIR/.env" ]]; then
    print_ok ".env: ADA"
    
    # Cek kelengkapan variable penting
    set -a
    source "$INSTALL_DIR/.env" 2>/dev/null || true
    set +a
    
    MISSING_VARS=()
    for var in TELEGRAM_TOKEN AUTHORIZED_USER_ID GEMINI_API_KEY; do
        if [[ -z "${!var:-}" ]]; then
            MISSING_VARS+=("$var")
        fi
    done
    
    if [[ ${#MISSING_VARS[@]} -eq 0 ]]; then
        print_ok ".env: LENGKAP (variable penting semua ada)"
    else
        print_warn ".env: TIDAK LENGKAP (variable hilang: ${MISSING_VARS[*]})"
        EXIT_CODE=1
    fi
else
    print_fail ".env: TIDAK ADA"
    EXIT_CODE=1
fi

# ============================================================
# 7. CEK LOG TERAKHIR (UNTUK DETEKSI CRASH LOOP)
# ============================================================
if [[ "$CONTAINER_RUNNING" == true ]]; then
    print_info "Memeriksa log terakhir untuk deteksi crash loop..."
    LAST_LOGS=$(docker logs --tail=5 "$CONTAINER_NAME" 2>/dev/null)
    
    if echo "$LAST_LOGS" | grep -qi "error\|fatal\|exception\|crash"; then
        print_warn "LOG: Terdapat indikasi error di log terakhir"
        print_info "  Periksa log lengkap: docker logs $CONTAINER_NAME"
        # Tidak langsung dianggap error, tapi warning
    else
        print_ok "LOG: Tidak ada error signifikan di log terakhir"
    fi
fi

# ============================================================
# 8. HASIL AKHIR
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 RINGKASAN HEALTH CHECK${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✅ SEMUA SISTEM SEHAT${NC}"
    echo -e "${GREEN}✅ Bot berjalan dengan normal.${NC}"
else
    echo -e "${YELLOW}⚠ BEBERAPA KOMPONEN BERMASALAH${NC}"
    echo ""
    echo "💡 Saran troubleshooting:"
    echo "  1. Periksa log lengkap: docker logs $CONTAINER_NAME"
    echo "  2. Periksa status: docker ps -a"
    echo "  3. Restart bot: docker compose -f $INSTALL_DIR/docker-compose.yml restart"
    echo "  4. Periksa .env: cat $INSTALL_DIR/.env"
fi

exit $EXIT_CODE