#!/bin/bash

# ============================================================
# FINANCE BOT — START BOT SCRIPT
# Version: 1.0.0
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    for dir in "$HOME/Telegram-Finance-Bot" "$HOME/finance-bot" "/opt/finance-bot" "$(pwd)"; do
        if [ -f "$dir/docker-compose.yml" ]; then
            PROJECT_DIR="$dir"
            break
        fi
    done
fi

cd "$PROJECT_DIR" || {
    echo -e "${RED}❌ Project directory not found${NC}"
    exit 1
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Starting Finance Bot...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Project: ${WHITE}$PROJECT_DIR${NC}"

if docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "finance-bot"; then
    echo -e "${YELLOW}ℹ️  Container already exists, starting...${NC}"
    docker start finance-bot
else
    echo -e "${YELLOW}ℹ️  Building and starting container...${NC}"
    docker compose up -d
fi

sleep 3

if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "finance-bot"; then
    echo -e "${GREEN}✅ Finance Bot is running${NC}"
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' finance-bot 2>/dev/null)
    echo -e "  Health: ${WHITE}$HEALTH${NC}"
else
    echo -e "${RED}❌ Failed to start Finance Bot${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"