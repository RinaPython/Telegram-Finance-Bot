#!/bin/bash

# ============================================================
# FINANCE BOT — DASHBOARD INSTALLER
# Version: 1.0.0
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DASHBOARD_SRC="$PROJECT_DIR/dashboard/finance-dashboard.sh"
DASHBOARD_DEST="/usr/local/bin/finance-dashboard"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 Installing Finance Dashboard...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f "$DASHBOARD_SRC" ]; then
    cp "$DASHBOARD_SRC" "$DASHBOARD_DEST"
    chmod +x "$DASHBOARD_DEST"
    echo -e "${GREEN}✅ Dashboard installed to: $DASHBOARD_DEST${NC}"
    echo -e "${GREEN}✅ Run: ${WHITE}finance-dashboard${NC}"
else
    echo -e "${RED}❌ Dashboard source not found: $DASHBOARD_SRC${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"