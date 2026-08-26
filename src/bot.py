"""Bot initialization and setup"""

import os
import time
import telegram
from telegram.ext import (
    Application,
    PicklePersistence,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    filters,
)

from src.config.settings import settings
from src.utils.logger import logger
from src.handlers.commands import (
    start, menu_command, help_command, me_command,
    toggle_delete_messages, record_command, delete_data,
    sheet_link_command, settings_command,
    settings_callback, menu_callback, button_callback,
)
from src.handlers.financial import (
    dashboard_command,
    pnl_command,
    report_command,
)
from src.handlers.transaction import (
    history_command,
    history_callback,
    message_handler,
    keyboard_handler,
    delete_callback,
    multiple_transactions_callback,
)
from src.handlers.receipt import photo_handler, receipt_callback
from src.services.google_sheets import init_google_sheets
from src.services.pnl_manager import PNLManager


# ============================================================
# HEALTH FILE — UNTUK DOCKER HEALTHCHECK
# ============================================================
HEALTH_FILE = "/app/health"


def update_health_file():
    """Update health file to indicate bot is running."""
    try:
        # Buat direktori jika belum ada
        os.makedirs(os.path.dirname(HEALTH_FILE), exist_ok=True)
        with open(HEALTH_FILE, 'w') as f:
            f.write(f"healthy:{time.time()}")
        return True
    except Exception as e:
        logger.warning(f"Could not update health file: {e}")
        return False


def create_bot() -> Application:
    """Create and configure the bot application."""
    
    # Initialize Google Sheets
    init_google_sheets()
    
    # Update PNL on startup
    PNLManager.update_pnl()
    
    # ============================================================
    # UPDATE HEALTH FILE (untuk Docker healthcheck)
    # ============================================================
    update_health_file()
    logger.info("✅ Health file updated on startup")
    
    # Create persistence
    persistence = PicklePersistence(filepath="/app/data/bot_data.pickle")
    
    application = Application.builder()\
        .token(settings.TELEGRAM_TOKEN)\
        .persistence(persistence)\
        .build()
    
    # Register command handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("menu", menu_command))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("me", me_command))
    application.add_handler(CommandHandler("catat", record_command))
    application.add_handler(CommandHandler("dashboard", dashboard_command))
    application.add_handler(CommandHandler("pnl", pnl_command))
    application.add_handler(CommandHandler("riwayat", history_command))
    application.add_handler(CommandHandler("laporan", report_command))
    application.add_handler(CommandHandler("sheet", sheet_link_command))
    application.add_handler(CommandHandler("hapus", delete_data))
    application.add_handler(CommandHandler("pengaturan", settings_command))
    application.add_handler(CommandHandler("settings", settings_command))
    application.add_handler(CommandHandler("hapuspesan", toggle_delete_messages))
    
    # Register callback handlers
    application.add_handler(CallbackQueryHandler(multiple_transactions_callback, pattern="^confirm_all_"))
    application.add_handler(CallbackQueryHandler(delete_callback, pattern="^delete_"))
    application.add_handler(CallbackQueryHandler(receipt_callback, pattern="^receipt_"))
    application.add_handler(CallbackQueryHandler(history_callback, pattern="^history_"))
    application.add_handler(CallbackQueryHandler(settings_callback, pattern="^settings_"))
    application.add_handler(CallbackQueryHandler(menu_callback, pattern="^menu_"))
    application.add_handler(CallbackQueryHandler(button_callback, pattern="^(confirm_|type_|cat_|edit_text)"))
    
    # Register photo handler
    application.add_handler(MessageHandler(
        filters.PHOTO & filters.ChatType.PRIVATE,
        photo_handler
    ))
    
    # Register keyboard handler
    application.add_handler(MessageHandler(
        filters.TEXT & ~filters.COMMAND & 
        filters.Regex("^(💳 Catat Transaksi|📊 Dashboard|📈 Profit & Loss|📋 Riwayat|🗑️ Hapus Data|📑 Google Sheets|⚙️ Pengaturan)$") & 
        filters.ChatType.PRIVATE,
        keyboard_handler
    ))
    
    # Register general message handler
    application.add_handler(MessageHandler(
        filters.TEXT & ~filters.COMMAND & filters.ChatType.PRIVATE,
        message_handler
    ))
    
    # Register error handler
    application.add_error_handler(error_handler)
    
    # Post init
    application.post_init = post_init
    
    # ============================================================
    # JOB QUEUE — Update health file setiap 30 detik
    # ============================================================
    application.job_queue.run_repeating(
        update_health_job,
        interval=30,
        first=10
    )
    
    return application


async def update_health_job(context):
    """Update health file periodically for Docker healthcheck."""
    update_health_file()


async def post_init(application: Application) -> None:
    """Set bot commands after initialization."""
    from telegram import BotCommand
    
    commands = [
        BotCommand("start", "Menu utama"),
        BotCommand("dashboard", "Dashboard keuangan"),
        BotCommand("pnl", "Profit & Loss"),
        BotCommand("riwayat", "Riwayat transaksi"),
        BotCommand("catat", "Catat transaksi"),
        BotCommand("laporan", "Laporan keuangan"),
        BotCommand("sheet", "Google Sheets"),
        BotCommand("hapus", "Hapus data"),
        BotCommand("menu", "Tampilkan menu"),
        BotCommand("help", "Panduan penggunaan"),
        BotCommand("pengaturan", "Pengaturan bot"),
    ]
    
    await application.bot.set_my_commands(commands)
    logger.info("✅ Bot commands registered")
    
    # ============================================================
    # UPDATE HEALTH FILE SETELAH INIT
    # ============================================================
    update_health_file()
    logger.info("✅ Health file updated after init")


async def error_handler(update, context):
    """Handle errors."""
    logger.error("Exception while handling an update:", exc_info=context.error)
    
    error = context.error
    
    if isinstance(error, telegram.error.Conflict):
        logger.error("🔴 Bot conflict detected - another instance is already running!")
        logger.error("💡 Stop the other instance or use the production bot directly")
        return
    
    if isinstance(error, telegram.error.NetworkError):
        logger.error("🌐 Network error occurred - this is usually temporary")
        return
    
    if isinstance(error, telegram.error.BadRequest):
        logger.error(f"🤖 Bad request: {error}")
        return
    
    if isinstance(error, telegram.error.Forbidden):
        logger.error(f"🚫 Forbidden: {error}")
        return
    
    if isinstance(error, telegram.error.TelegramError):
        logger.error(f"🤖 Telegram API error: {error}")
        return
    
    logger.error(f"💥 Unexpected error: {error}", exc_info=True)