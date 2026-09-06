"""Financial command handlers (Dashboard, PNL, Report) — BAHASA INDONESIA"""

from datetime import datetime
from telegram import Update
from telegram.ext import ContextTypes

from src.config.settings import settings
from src.utils.logger import logger
from src.utils.formatters import format_rupiah, get_category_emoji, escape_markdown
from src.services.google_sheets import get_google_sheets
from src.services.financial_analytics import FinancialAnalytics
from src.services.pnl_manager import PNLManager
from src.utils.timezone import now, today, get_current_month


# ============================================================
# COMMAND FUNCTIONS (untuk /command)
# ============================================================

async def dashboard_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /dashboard command."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung. Dashboard tidak tersedia.")
        return
    
    await update.message.reply_text("📊 Menghitung data keuangan...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await update.message.reply_text(
                "📊 *DASHBOARD*\n\n"
                "Belum ada data keuangan.\n\n"
                "💡 Mulai catat transaksi dengan mengirim pesan seperti:\n"
                "• `Beli makan siang 50000`\n"
                "• `Terima gaji 5000000`",
                parse_mode='Markdown'
            )
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        # ============================================================
        # DASHBOARD — JUDUL INGGRIS, ISI INDONESIA
        # ============================================================
        dashboard_text = (
            "📊 *DASHBOARD KEUANGAN*\n\n"
            f"💰 *Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            dashboard_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            dashboard_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        dashboard_text += (
            f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%\n\n"
            f"📝 *Total Transaksi*\n{len(transactions)}\n\n"
            "📋 *Transaksi Terakhir*\n"
        )
        
        for t in transactions[:5]:
            try:
                amount = float(t.get('Amount', 0))
                desc = t.get('Description', '')[:25]
                if desc == '':
                    desc = 'Transaksi'
                if amount > 0:
                    dashboard_text += f"💰 +{format_rupiah(amount)} — {desc}\n"
                else:
                    dashboard_text += f"💸 -{format_rupiah(abs(amount))} — {desc}\n"
            except:
                continue
        
        await update.message.reply_text(dashboard_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error dashboard: {e}", exc_info=True)
        await update.message.reply_text(
            "⚠️ Maaf, terjadi kendala saat mengambil data.\n"
            "Silakan coba lagi nanti."
        )


async def pnl_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /pnl command."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await update.message.reply_text("📈 Menghitung Profit & Loss...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await update.message.reply_text(
                "📈 *PROFIT & LOSS*\n\n"
                "Belum ada data untuk PNL.\n\n"
                "💡 Mulai catat transaksi untuk melihat laporan keuangan.",
                parse_mode='Markdown'
            )
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        # ============================================================
        # PNL — JUDUL INGGRIS, ISI INDONESIA
        # ============================================================
        pnl_text = (
            "📈 *PROFIT & LOSS*\n\n"
            f"💰 *Total Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Total Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            pnl_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            pnl_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        pnl_text += f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%"
        
        await update.message.reply_text(pnl_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error PNL: {e}", exc_info=True)
        await update.message.reply_text(
            "⚠️ Maaf, terjadi kendala saat menghitung PNL.\n"
            "Silakan coba lagi nanti."
        )


async def report_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /laporan command."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await update.message.reply_text("📊 Menyusun laporan...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await update.message.reply_text("❌ Anda belum memiliki catatan keuangan.")
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        # ============================================================
        # LAPORAN — JUDUL INGGRIS, ISI INDONESIA
        # ============================================================
        report_text = (
            "📊 *LAPORAN KEUANGAN*\n"
            f"_Per {now().strftime('%d %B %Y')}_\n\n"
            f"💰 *Total Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Total Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            report_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            report_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        report_text += (
            f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%\n\n"
            f"📝 *Total Transaksi*\n{len(transactions)}\n\n"
            "📋 *5 Transaksi Terakhir*\n"
        )
        
        for t in transactions[:5]:
            try:
                amount = float(t.get('Amount', 0))
                desc = t.get('Description', '')[:20]
                if desc == '':
                    desc = 'Transaksi'
                if amount > 0:
                    report_text += f"💰 +{format_rupiah(amount)} — {desc}\n"
                else:
                    report_text += f"💸 -{format_rupiah(abs(amount))} — {desc}\n"
            except:
                continue
        
        await update.message.reply_text(report_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error report: {e}", exc_info=True)
        await update.message.reply_text(
            "⚠️ Maaf, terjadi kendala saat mengambil laporan.\n"
            "Silakan coba lagi nanti."
        )


# ============================================================
# CALLBACK FUNCTIONS (untuk menu_callback)
# ============================================================

async def dashboard_command_from_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Dashboard command yang dipanggil dari callback."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung. Dashboard tidak tersedia.")
        return
    
    await query.edit_message_text("📊 Menghitung data keuangan...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await query.edit_message_text(
                "📊 *DASHBOARD*\n\n"
                "Belum ada data keuangan.\n\n"
                "💡 Mulai catat transaksi dengan mengirim pesan seperti:\n"
                "• `Beli makan siang 50000`\n"
                "• `Terima gaji 5000000`",
                parse_mode='Markdown'
            )
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        dashboard_text = (
            "📊 *DASHBOARD KEUANGAN*\n\n"
            f"💰 *Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            dashboard_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            dashboard_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        dashboard_text += (
            f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%\n\n"
            f"📝 *Total Transaksi*\n{len(transactions)}\n\n"
            "📋 *Transaksi Terakhir*\n"
        )
        
        for t in transactions[:5]:
            try:
                amount = float(t.get('Amount', 0))
                desc = t.get('Description', '')[:25]
                if desc == '':
                    desc = 'Transaksi'
                if amount > 0:
                    dashboard_text += f"💰 +{format_rupiah(amount)} — {desc}\n"
                else:
                    dashboard_text += f"💸 -{format_rupiah(abs(amount))} — {desc}\n"
            except:
                continue
        
        await query.edit_message_text(dashboard_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error dashboard callback: {e}", exc_info=True)
        await query.edit_message_text(
            "⚠️ Maaf, terjadi kendala saat mengambil data.\n"
            "Silakan coba lagi nanti."
        )


async def pnl_command_from_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """PNL command yang dipanggil dari callback."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await query.edit_message_text("📈 Menghitung Profit & Loss...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await query.edit_message_text(
                "📈 *PROFIT & LOSS*\n\n"
                "Belum ada data untuk PNL.\n\n"
                "💡 Mulai catat transaksi untuk melihat laporan keuangan.",
                parse_mode='Markdown'
            )
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        pnl_text = (
            "📈 *PROFIT & LOSS*\n\n"
            f"💰 *Total Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Total Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            pnl_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            pnl_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        pnl_text += f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%"
        
        await query.edit_message_text(pnl_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error PNL callback: {e}", exc_info=True)
        await query.edit_message_text(
            "⚠️ Maaf, terjadi kendala saat menghitung PNL.\n"
            "Silakan coba lagi nanti."
        )


async def history_command_from_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """History command yang dipanggil dari callback."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await query.edit_message_text("📋 Mengambil riwayat...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await query.edit_message_text(
                "📋 *RIWAYAT TRANSAKSI*\n\n"
                "Belum ada transaksi.\n\n"
                "💡 Mulai catat transaksi untuk melihat riwayat.",
                parse_mode='Markdown'
            )
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        history_text = (
            "📋 *RIWAYAT TRANSAKSI*\n\n"
            f"💰 Total Pemasukan: {format_rupiah(total_income)}\n"
            f"💸 Total Pengeluaran: {format_rupiah(total_expense)}\n"
            f"📊 Selisih: {format_rupiah(total_income - total_expense)}\n\n"
            "📌 *Transaksi Terakhir*\n"
        )
        
        for i, t in enumerate(transactions[:10], 1):
            try:
                date = t.get('Date', '')
                amount = float(t.get('Amount', 0))
                desc = t.get('Description', '')[:30]
                if desc == '':
                    desc = 'Transaksi'
                cat = t.get('Category', 'Lainnya')
                if cat == '':
                    cat = 'Lainnya'
                emoji = get_category_emoji(cat)
                
                try:
                    date_obj = datetime.strptime(date, '%Y-%m-%d')
                    date_display = date_obj.strftime('%d/%m/%Y')
                except:
                    date_display = date if date else 'N/A'
                
                if amount > 0:
                    history_text += f"{i}. 📅 {date_display}  💰 +{format_rupiah(amount)}  {desc}\n"
                else:
                    history_text += f"{i}. 📅 {date_display}  💸 -{format_rupiah(abs(amount))}  {desc}\n"
            except Exception as e:
                continue
        
        if len(transactions) > 10:
            history_text += f"\n... dan {len(transactions) - 10} transaksi lainnya"
        
        history_text += "\n\n💡 Gunakan `/laporan` untuk detail lengkap."
        
        await query.edit_message_text(history_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error history callback: {e}", exc_info=True)
        await query.edit_message_text(
            "⚠️ Maaf, terjadi kendala saat mengambil riwayat.\n"
            "Silakan coba lagi nanti."
        )


async def report_command_from_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Report command yang dipanggil dari callback."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await query.edit_message_text("📊 Menyusun laporan...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await query.edit_message_text("❌ Anda belum memiliki catatan keuangan.")
            return
        
        total_income = 0
        total_expense = 0
        for t in transactions:
            try:
                amount = float(t.get('Amount', 0))
                if amount > 0:
                    total_income += amount
                elif amount < 0:
                    total_expense += abs(amount)
            except:
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        report_text = (
            "📊 *LAPORAN KEUANGAN*\n"
            f"_Per {now().strftime('%d %B %Y')}_\n\n"
            f"💰 *Total Pemasukan*\n{format_rupiah(total_income)}\n\n"
            f"💸 *Total Pengeluaran*\n{format_rupiah(total_expense)}\n\n"
        )
        
        if net_profit >= 0:
            report_text += f"📈 *Laba Bersih*\n{format_rupiah(net_profit)}\n\n"
        else:
            report_text += f"📉 *Rugi Bersih*\n{format_rupiah(abs(net_profit))}\n\n"
        
        report_text += (
            f"💎 *Tingkat Tabungan*\n{savings_rate:.1f}%\n\n"
            f"📝 *Total Transaksi*\n{len(transactions)}\n\n"
            "📋 *5 Transaksi Terakhir*\n"
        )
        
        for t in transactions[:5]:
            try:
                amount = float(t.get('Amount', 0))
                desc = t.get('Description', '')[:20]
                if desc == '':
                    desc = 'Transaksi'
                if amount > 0:
                    report_text += f"💰 +{format_rupiah(amount)} — {desc}\n"
                else:
                    report_text += f"💸 -{format_rupiah(abs(amount))} — {desc}\n"
            except:
                continue
        
        await query.edit_message_text(report_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error report callback: {e}", exc_info=True)
        await query.edit_message_text(
            "⚠️ Maaf, terjadi kendala saat mengambil laporan.\n"
            "Silakan coba lagi nanti."
        )