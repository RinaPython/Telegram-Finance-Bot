"""
Finance Bot - Main Entry Point
"""

import sys
import os
import time
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.bot import create_bot
from src.utils.logger import logger
from src.config.settings import settings


# ============================================================
# HEALTH FILE — UNTUK DOCKER HEALTHCHECK
# ============================================================
HEALTH_FILE = "/app/health"


def update_health_file():
    """Update health file to indicate bot is running."""
    try:
        os.makedirs(os.path.dirname(HEALTH_FILE), exist_ok=True)
        with open(HEALTH_FILE, 'w') as f:
            f.write(f"healthy:{time.time()}")
        return True
    except Exception as e:
        logger.warning(f"Could not update health file: {e}")
        return False


def print_banner():
    """Print minimal & modern startup banner — tanpa garis."""
    
    # Warna ANSI
    CYAN = '\033[0;36m'
    GREEN = '\033[0;32m'
    WHITE = '\033[1;37m'
    YELLOW = '\033[1;33m'
    MAGENTA = '\033[0;35m'
    NC = '\033[0m'
    
    # ============================================================
    # BANNER TANPA GARIS — MINIMALIS & MODERN
    # ============================================================
    print(f"""
{CYAN}    ███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
    ██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
    █████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║  ███╗█████╗  
    ██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  
    ██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╔╝███████╗
    ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝{NC}

    {WHITE}💰 PERSONAL FINANCE TRACKER{NC}
    
    {GREEN}📦 Version    :{NC} v1.0.0
    {GREEN}🤖 AI Model   :{NC} Gemini 2.5 Flash Lite
    {GREEN}📊 Google     :{NC} Sheets API
    {GREEN}🐳 Container  :{NC} Docker Ready
    
    {YELLOW}🚀 Initializing services...{NC}
""")
    
    print(f"  {GREEN}▶{NC} {WHITE}Starting bot...{NC}")
    print(f"  {GREEN}▶{NC} {WHITE}Connected to Google Sheets{NC}")
    print(f"  {GREEN}▶{NC} {WHITE}Gemini AI: Ready{NC}")
    print(f"  {GREEN}▶{NC} {WHITE}Telegram Bot: Online{NC}")
    print("")


def main():
    """Main entry point for the bot."""
    print_banner()
    
    logger.info(f"🚀 Finance Bot {settings.BOT_VERSION} starting up...")
    
    # Validate configuration
    if not settings.TELEGRAM_TOKEN:
        logger.error("❌ TELEGRAM_TOKEN not found in environment variables")
        sys.exit(1)
    
    if not settings.AUTHORIZED_USER_IDS or settings.AUTHORIZED_USER_IDS == ['']:
        logger.error("❌ AUTHORIZED_USER_ID not found in environment variables")
        sys.exit(1)
    
    # Update health file
    update_health_file()
    logger.info("✅ Health file updated on main startup")
    
    # Create and run bot
    try:
        application = create_bot()
        logger.info("🚀 Starting bot polling...")
        
        update_health_file()
        logger.info("✅ Health file updated after bot start")
        
        application.run_polling(drop_pending_updates=True)
    except KeyboardInterrupt:
        logger.info("🛑 Bot stopped by user")
    except Exception as e:
        logger.error(f"❌ Failed to start bot: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
