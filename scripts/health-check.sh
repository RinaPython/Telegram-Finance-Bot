#!/bin/bash

# ============================================================
# FINANCE BOT — HEALTH CHECK SCRIPT
# Version: 1.0.0
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR" || exit 1

echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}🏥 FINANCE BOT — HEALTH CHECK${NC}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -n "  Docker: "
if docker ps &>/dev/null; then
    echo -e "${GREEN}RUNNING${NC}"
else
    echo -e "${RED}STOPPED${NC}"
    exit 1
fi

echo -n "  Container: "
if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "finance-bot"; then
    echo -e "${GREEN}RUNNING${NC}"
else
    echo -e "${RED}STOPPED${NC}"
    exit 1
fi

echo -n "  Health: "
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' finance-bot 2>/dev/null)
if [ "$HEALTH" = "healthy" ]; then
    echo -e "${GREEN}HEALTHY${NC}"
elif [ "$HEALTH" = "unhealthy" ]; then
    echo -e "${RED}UNHEALTHY${NC}"
    exit 1
else
    echo -e "${YELLOW}$HEALTH${NC}"
fi

echo -n "  Restarts: "
RESTARTS=$(docker inspect --format='{{.RestartCount}}' finance-bot 2>/dev/null)
echo -e "${WHITE}$RESTARTS${NC}"

echo -n "  Uptime: "
UPTIME=$(docker ps --format "{{.Status}}" --filter "name=finance-bot" 2>/dev/null)
echo -e "${WHITE}${UPTIME:-N/A}${NC}"

echo -n "  Telegram API: "
if curl -s -o /dev/null -w "%{http_code}" https://api.telegram.org | grep -q "200"; then
    echo -e "${GREEN}REACHABLE${NC}"
else
    echo -e "${YELLOW}UNREACHABLE${NC}"
fi

echo ""
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$HEALTH" = "healthy" ]; then
    exit 0
else
    exit 1
fi