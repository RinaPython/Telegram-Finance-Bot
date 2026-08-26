"""Transaction handlers for recording, history, deletion, and auto-delete messages"""

import re
import asyncio
import uuid
from datetime import datetime
from typing import List, Dict, Any
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes

from src.config.settings import settings
from src.config.constants import STATE_WAITING_AMOUNT
from src.utils.logger import logger
from src.utils.formatters import format_rupiah, get_category_emoji, escape_markdown
from src.utils.parsers import parse_indonesian_amount, parse_date_from_text, parse_transaction_locally
from src.utils.timezone import now, today, get_timestamp
from src.services.google_sheets import get_google_sheets
from src.services.financial_analytics import FinancialAnalytics
from src.services.gemini_ai import gemini_service
from src.services.pnl_manager import PNLManager
from src.models.transaction import Transaction


# ============================================================
# HAPUS PESAN OTOMATIS — 3 DETIK
# ============================================================

async def delete_old_messages(context: ContextTypes.DEFAULT_TYPE):
    """Hapus pesan lama setelah transaksi selesai — dengan error handling."""
    job_data = context.job.data
    chat_id = job_data['chat_id']
    user_id = job_data['user_id']
    
    user_data = context.application.user_data.get(user_id, {})
    
    if not user_data.get('delete_messages', True):
        return
    
    messages_to_delete = user_data.get('messages_to_delete', [])
    
    if not messages_to_delete:
        return
    
    deleted_count = 0
    for message_id in messages_to_delete:
        try:
            await context.bot.delete_message(chat_id=chat_id, message_id=message_id)
            deleted_count += 1
        except Exception as e:
            error_str = str(e).lower()
            if 'message to delete not found' in error_str:
                continue
            elif 'message can\'t be deleted' in error_str:
                continue
            elif 'not enough rights' in error_str:
                continue
            else:
                logger.warning(f"Gagal hapus pesan {message_id}: {e}")
    
    context.application.user_data[user_id]['messages_to_delete'] = []
    
    if deleted_count > 0:
        logger.info(f"✅ {deleted_count} pesan dihapus untuk user {user_id}")


def schedule_delete_messages(context: ContextTypes.DEFAULT_TYPE, chat_id: int, user_id: int):
    """Jadwalkan penghapusan pesan setelah 3 detik."""
    if context.job_queue:
        context.job_queue.run_once(
            delete_old_messages,
            when=3,
            data={
                'chat_id': chat_id,
                'user_id': user_id
            }
        )
    else:
        logger.error("❌ job_queue is None, tidak bisa schedule delete")


# ============================================================
# HISTORY COMMAND
# ============================================================

async def history_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /riwayat command."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    await update.message.reply_text("📋 Mengambil riwayat...")
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        transactions = gs.get_transactions(str(user_id))
        
        if not transactions:
            await update.message.reply_text(
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
                logger.warning(f"Error formatting transaction: {e}")
                continue
        
        if len(transactions) > 10:
            history_text += f"\n... dan {len(transactions) - 10} transaksi lainnya"
        
        history_text += "\n\n💡 Gunakan `/laporan` untuk detail lengkap."
        
        await update.message.reply_text(history_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error history: {e}", exc_info=True)
        await update.message.reply_text(
            "⚠️ Maaf, terjadi kendala saat mengambil riwayat.\n"
            "Silakan coba lagi nanti."
        )


async def history_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle history pagination callbacks."""
    query = update.callback_query
    await query.answer()
    
    if query.data == "history_close":
        await query.edit_message_text("📋 Riwayat ditutup.")
        return
    
    if query.data.startswith("history_page_"):
        try:
            page = int(query.data.split("_")[2])
            await _show_history_page(update, context, page)
        except (ValueError, IndexError) as e:
            logger.error(f"Invalid history page callback: {query.data}")


async def _show_history_page(update: Update, context: ContextTypes.DEFAULT_TYPE, page: int):
    """Show a specific page of transaction history."""
    transactions = context.user_data.get('history_transactions', [])
    page_size = context.user_data.get('history_page_size', 5)
    total_pages = (len(transactions) + page_size - 1) // page_size
    
    if page < 0:
        page = 0
    if page >= total_pages:
        page = total_pages - 1
    
    start_idx = page * page_size
    end_idx = min(start_idx + page_size, len(transactions))
    page_transactions = transactions[start_idx:end_idx]
    
    history_text = "📋 *RIWAYAT TRANSAKSI*\n\n"
    
    for t in page_transactions:
        try:
            date_str = t.get('Date', '')
            amount = float(t.get('Amount', 0))
            category = t.get('Category', 'Lainnya')
            description = t.get('Description', '')
            emoji = get_category_emoji(category)
            
            try:
                date_obj = datetime.strptime(date_str, '%Y-%m-%d')
                history_text += f"📅 {date_obj.strftime('%d %B %Y')}\n"
            except:
                history_text += f"📅 {date_str}\n"
            
            if amount > 0:
                history_text += f"   💰 {emoji} {category}\n"
                history_text += f"   {format_rupiah(amount)}\n\n"
            else:
                history_text += f"   💸 {emoji} {category}\n"
                history_text += f"   {format_rupiah(abs(amount))}\n\n"
                
        except Exception as e:
            logger.warning(f"Error formatting transaction: {e}")
            continue
    
    keyboard = []
    nav_row = []
    
    if page > 0:
        nav_row.append(InlineKeyboardButton("⬅️", callback_data=f"history_page_{page - 1}"))
    
    nav_row.append(InlineKeyboardButton(f"{page + 1}/{total_pages}", callback_data="history_page_current"))
    
    if page < total_pages - 1:
        nav_row.append(InlineKeyboardButton("➡️", callback_data=f"history_page_{page + 1}"))
    
    keyboard.append(nav_row)
    keyboard.append([InlineKeyboardButton("❌ Tutup", callback_data="history_close")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    if update.callback_query:
        await update.callback_query.edit_message_text(history_text, parse_mode='Markdown', reply_markup=reply_markup)
        await update.callback_query.answer()
    else:
        await update.message.reply_text(history_text, parse_mode='Markdown', reply_markup=reply_markup)


# ============================================================
# DELETE CALLBACK — DENGAN AUTO UPDATE PNL
# ============================================================

async def delete_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle delete callbacks — dengan auto update PNL."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    
    if query.data == "delete_cancel":
        await query.edit_message_text("❌ Dibatalkan.")
        return
    
    action = query.data.split("_")[1] if "_" in query.data else query.data
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        if action == "last":
            transactions = gs.get_transactions(str(user_id))
            if not transactions:
                await query.edit_message_text("❌ Tidak ada transaksi.")
                return
            
            last = transactions[0]
            transaction_id = last.get('ID') or last.get('Timestamp')
            
            if transaction_id and gs.delete_transaction(str(user_id), transaction_id):
                PNLManager.update_pnl(str(user_id))
                amount = float(last.get('Amount', 0))
                txn_type = "Pemasukan" if amount > 0 else "Pengeluaran"
                await query.edit_message_text(
                    f"✅ Transaksi terakhir dihapus!\n\n"
                    f"📊 Jenis: {txn_type}\n"
                    f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
                    f"🏷️ Kategori: {last.get('Category', 'Lainnya')}"
                )
            else:
                await query.edit_message_text("❌ Gagal menghapus.")
        
        elif action == "all":
            count = gs.delete_all_transactions(str(user_id))
            PNLManager.clear_pnl(str(user_id))
            await query.edit_message_text(f"✅ {count} transaksi dihapus.")
        
        elif action == "date":
            context.user_data['delete_state'] = 'awaiting_start_date'
            await query.edit_message_text("📅 Masukkan tanggal awal (YYYY-MM-DD):")
        
    except Exception as e:
        logger.error(f"Error delete callback: {e}", exc_info=True)
        await query.edit_message_text("⚠️ Maaf, terjadi kendala.")


async def handle_date_input(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle date input for deletion — dengan auto update PNL."""
    user_id = update.effective_user.id
    message_text = update.message.text.strip()
    
    if 'delete_state' not in context.user_data:
        return
    
    if message_text.lower() in ['batal', 'cancel']:
        context.user_data.pop('delete_state', None)
        context.user_data.pop('start_date', None)
        await update.message.reply_text("❌ Dibatalkan.")
        return
    
    if not re.match(r'^\d{4}-\d{2}-\d{2}$', message_text):
        await update.message.reply_text("❌ Format salah. Gunakan YYYY-MM-DD")
        return
    
    state = context.user_data['delete_state']
    
    if state == 'awaiting_start_date':
        context.user_data['start_date'] = message_text
        context.user_data['delete_state'] = 'awaiting_end_date'
        await update.message.reply_text("📅 Masukkan tanggal akhir (YYYY-MM-DD):")
    
    elif state == 'awaiting_end_date':
        start_date = context.user_data['start_date']
        end_date = message_text
        
        if end_date < start_date:
            await update.message.reply_text("❌ Tanggal akhir harus setelah tanggal awal.")
            return
        
        try:
            gs = get_google_sheets()
            if not gs or not gs.is_initialized:
                await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
                return
            
            transactions = gs.get_transactions_by_date(str(user_id), start_date, end_date)
            
            if not transactions:
                await update.message.reply_text(f"❌ Tidak ada transaksi {start_date} - {end_date}.")
                context.user_data.pop('delete_state', None)
                context.user_data.pop('start_date', None)
                return
            
            deleted = 0
            for t in transactions:
                tid = t.get('ID') or t.get('Timestamp')
                if tid and gs.delete_transaction(str(user_id), tid):
                    deleted += 1
            
            if deleted > 0:
                PNLManager.update_pnl(str(user_id))
            else:
                PNLManager.clear_pnl(str(user_id))
            
            context.user_data.pop('delete_state', None)
            context.user_data.pop('start_date', None)
            
            await update.message.reply_text(f"✅ {deleted} transaksi dihapus.")
            
        except Exception as e:
            logger.error(f"Error delete by date: {e}", exc_info=True)
            await update.message.reply_text("⚠️ Maaf, terjadi kendala.")


async def keyboard_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle keyboard button presses."""
    text = update.message.text
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if text == "💳 Catat Transaksi":
        from src.handlers.commands import record_command
        await record_command(update, context)
    elif text == "📊 Dashboard":
        from src.handlers.financial import dashboard_command
        await dashboard_command(update, context)
    elif text == "📈 Profit & Loss":
        from src.handlers.financial import pnl_command
        await pnl_command(update, context)
    elif text == "📋 Riwayat":
        await history_command(update, context)
    elif text == "📑 Laporan":
        from src.handlers.financial import report_command
        await report_command(update, context)
    elif text == "🗑️ Hapus Data":
        from src.handlers.commands import delete_data
        await delete_data(update, context)
    elif text == "📑 Google Sheets":
        from src.handlers.commands import sheet_link_command
        await sheet_link_command(update, context)
    elif text == "⚙️ Pengaturan":
        from src.handlers.commands import settings_command
        await settings_command(update, context)


# ============================================================
# MESSAGE HANDLER
# ============================================================

async def message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Main message handler — dengan perbaikan mode delete."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if context.user_data.get('delete_state'):
        message_text = update.message.text.strip()
        
        if message_text.lower() in ['batal', 'cancel', 'batalkan']:
            context.user_data.pop('delete_state', None)
            context.user_data.pop('start_date', None)
            await update.message.reply_text("❌ Penghapusan berdasarkan tanggal dibatalkan.")
            return
        
        if message_text.startswith('/'):
            context.user_data.pop('delete_state', None)
            context.user_data.pop('start_date', None)
            return
        
        await handle_date_input(update, context)
        return
    
    if context.user_data.get('waiting_edit_text'):
        message_text = update.message.text.strip()
        
        if message_text.lower() in ['batal', 'cancel', 'batalkan']:
            context.user_data.pop('waiting_edit_text', None)
            context.user_data.pop('pending_transaction', None)
            context.user_data.pop('pending_message', None)
            await update.message.reply_text("❌ Edit teks dibatalkan.")
            return
        
        if settings.is_gemini_enabled() and gemini_service.is_available():
            parsed_data = await gemini_service.parse_financial_data(message_text)
        else:
            parsed_data = parse_transaction_locally(message_text)
        
        amount = parsed_data.get('amount')
        if not amount:
            amount = parse_indonesian_amount(message_text)
        
        clean_description = message_text
        if amount:
            clean_description = re.sub(r'\d+(?:[.,]\d+)?\s*(?:juta|jt|ribu|rb|k)?', '', message_text, flags=re.IGNORECASE)
            clean_description = re.sub(r'rp\.?\s*', '', clean_description, flags=re.IGNORECASE)
            clean_description = re.sub(r'[0-9,.\-]+', '', clean_description)
            clean_description = clean_description.strip()
            
            if not clean_description:
                text_lower = message_text.lower()
                if 'saldo' in text_lower:
                    clean_description = 'Saldo'
                elif 'gaji' in text_lower:
                    clean_description = 'Gaji'
                elif 'bonus' in text_lower:
                    clean_description = 'Bonus'
                elif 'makan' in text_lower:
                    clean_description = 'Makan'
                elif 'beli' in text_lower or 'belanja' in text_lower:
                    clean_description = 'Belanja'
                elif 'bayar' in text_lower or 'tagihan' in text_lower:
                    clean_description = 'Tagihan'
                else:
                    clean_description = 'Transaksi'
        else:
            clean_description = message_text
        
        context.user_data['pending_message'] = message_text
        context.user_data['pending_transaction'] = {
            'date': parsed_data.get('date', today()),
            'amount': amount if amount else 0,
            'category': parsed_data.get('category', 'Lainnya'),
            'description': clean_description
        }
        context.user_data.pop('waiting_edit_text', None)
        
        if amount:
            transaction_type = "Pemasukan" if amount > 0 else "Pengeluaran"
            safe_description = escape_markdown(clean_description)
            confirmation_message = f"📝 *Detail Transaksi (Setelah Edit)*\n\n"
            confirmation_message += f"📅 Tanggal: {parsed_data.get('date', today())}\n"
            confirmation_message += f"📊 Jenis: {transaction_type}\n"
            confirmation_message += f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
            confirmation_message += f"🏷️ Kategori: {parsed_data.get('category', 'Lainnya')}\n"
            confirmation_message += f"📄 Deskripsi: {safe_description}\n\n"
            confirmation_message += "Apakah data ini benar?"
            
            keyboard = [
                [InlineKeyboardButton("✅ Ya", callback_data="confirm_yes"),
                 InlineKeyboardButton("✏️ Edit Lagi", callback_data="confirm_edit")],
                [InlineKeyboardButton("❌ Batal", callback_data="confirm_cancel")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await update.message.reply_text(confirmation_message, reply_markup=reply_markup, parse_mode='Markdown')
        else:
            keyboard = [
                [InlineKeyboardButton("💰 Pemasukan", callback_data="type_income"),
                 InlineKeyboardButton("💸 Pengeluaran", callback_data="type_expense")],
                [InlineKeyboardButton("❌ Batal", callback_data="confirm_cancel")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            context.user_data['pending_message'] = message_text
            context.user_data['detected_date'] = parsed_data.get('date', today())
            context.user_data['pending_category'] = parsed_data.get('category', 'Lainnya')
            
            await update.message.reply_text(
                "Saya tidak dapat menentukan jumlah. Apakah ini pemasukan atau pengeluaran?",
                reply_markup=reply_markup
            )
        return
    
    message_text = update.message.text
    if message_text.startswith('/'):
        return
    
    await process_financial_message(update, context)


# ============================================================
# FINANCIAL MESSAGE PROCESSING
# ============================================================

async def process_financial_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Process financial messages from users."""
    user_id = update.effective_user.id
    chat_id = update.effective_chat.id
    
    if 'messages_to_delete' not in context.user_data:
        context.user_data['messages_to_delete'] = []
    
    if len(context.user_data['messages_to_delete']) > 50:
        old_messages = context.user_data['messages_to_delete'][:10]
        for msg_id in old_messages:
            try:
                await context.bot.delete_message(chat_id=chat_id, message_id=msg_id)
            except:
                pass
        context.user_data['messages_to_delete'] = context.user_data['messages_to_delete'][10:]
    
    context.user_data['messages_to_delete'].append(update.message.message_id)
    
    message_text = update.message.text
    
    if context.user_data.get('conversation_state') == STATE_WAITING_AMOUNT:
        amount = parse_indonesian_amount(message_text)
        
        if amount is not None:
            transaction_type = context.user_data.get('transaction_type', 'expense')
            description = context.user_data.get('description', '')
            detected_date = context.user_data.get('date', today())
            category = context.user_data.get('pending_category', 'Lainnya')
            
            if transaction_type == 'expense':
                amount = -abs(amount)
            else:
                amount = abs(amount)
            
            context.user_data['conversation_state'] = None
            
            context.user_data['pending_transaction'] = {
                'date': detected_date,
                'amount': amount,
                'category': category,
                'description': description
            }
            
            type_display = "Pemasukan" if amount > 0 else "Pengeluaran"
            safe_description = escape_markdown(description)
            confirmation_message = f"📝 *Detail Transaksi*\n\n"
            confirmation_message += f"📅 Tanggal: {detected_date}\n"
            confirmation_message += f"📊 Jenis: {type_display}\n"
            confirmation_message += f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
            confirmation_message += f"🏷️ Kategori: {category}\n"
            confirmation_message += f"📄 Deskripsi: {safe_description}\n\n"
            confirmation_message += "Apakah data ini benar?"
            
            keyboard = [
                [InlineKeyboardButton("✅ Ya", callback_data="confirm_yes"),
                 InlineKeyboardButton("✏️ Edit", callback_data="confirm_edit")],
                [InlineKeyboardButton("🚫 Batal", callback_data="confirm_cancel")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await update.message.reply_text(confirmation_message, reply_markup=reply_markup, parse_mode='Markdown')
            return
        else:
            await update.message.reply_text(
                "❌ Format jumlah tidak valid.\n\n"
                "Contoh: 50000, 50k, 50rb, 1jt\n\n"
                "Silakan masukkan jumlah lagi:"
            )
            return
    
    lines = [line.strip() for line in message_text.split('\n') if line.strip()]
    
    if len(lines) > 1:
        transactions = await parse_multiple_transactions(message_text)
        if transactions:
            await process_multiple_transactions(update, context, transactions)
        else:
            await update.message.reply_text("❌ Saya tidak dapat mengenali transaksi.")
        return
    
    if settings.is_gemini_enabled() and gemini_service.is_available():
        parsed_data = await gemini_service.parse_financial_data(message_text)
    else:
        parsed_data = parse_transaction_locally(message_text)
    
    if not parsed_data.get('date'):
        parsed_data['date'] = parse_date_from_text(message_text)
    
    if not parsed_data.get('amount'):
        keyboard = [
            [InlineKeyboardButton("💰 Pemasukan", callback_data="type_income"),
             InlineKeyboardButton("💸 Pengeluaran", callback_data="type_expense")],
            [InlineKeyboardButton("❌ Batal", callback_data="confirm_cancel")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        context.user_data['pending_message'] = message_text
        context.user_data['detected_date'] = parsed_data.get('date', today())
        context.user_data['pending_category'] = parsed_data.get('category', 'Lainnya')
        
        await update.message.reply_text(
            "Saya tidak dapat menentukan jenis transaksi. Apakah ini pemasukan atau pengeluaran?",
            reply_markup=reply_markup
        )
        return
    
    amount = parsed_data.get('amount', 0)
    transaction_type = "Pemasukan" if amount > 0 else "Pengeluaran"
    category = parsed_data.get('category', 'Lainnya')
    description = parsed_data.get('description', message_text)
    date = parsed_data.get('date', today())
    
    safe_description = escape_markdown(description)
    confirmation_message = f"📝 *Detail Transaksi*\n\n"
    confirmation_message += f"📅 Tanggal: {date}\n"
    confirmation_message += f"📊 Jenis: {transaction_type}\n"
    confirmation_message += f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
    confirmation_message += f"🏷️ Kategori: {category}\n"
    confirmation_message += f"📄 Deskripsi: {safe_description}\n\n"
    confirmation_message += "Apakah data ini benar?"
    
    context.user_data['pending_transaction'] = {
        'date': date,
        'amount': amount,
        'category': category,
        'description': description
    }
    
    keyboard = [
        [InlineKeyboardButton("✅ Ya", callback_data="confirm_yes"),
         InlineKeyboardButton("✏️ Edit", callback_data="confirm_edit")],
        [InlineKeyboardButton("🚫 Batal", callback_data="confirm_cancel")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(confirmation_message, reply_markup=reply_markup, parse_mode='Markdown')


# ============================================================
# MULTIPLE TRANSACTIONS
# ============================================================

async def parse_multiple_transactions(text: str) -> List[Dict[str, Any]]:
    """Parse multiple transactions from text."""
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    if not lines:
        return []
    
    transactions = []
    for line in lines:
        try:
            if settings.is_gemini_enabled() and gemini_service.is_available():
                transaction_data = await gemini_service.parse_financial_data(line)
            else:
                transaction_data = parse_transaction_locally(line)
            
            if transaction_data.get('amount') is not None:
                transactions.append(transaction_data)
        except Exception as e:
            logger.warning(f"Error parsing line '{line}': {e}")
            continue
    
    return transactions


async def process_multiple_transactions(update: Update, context: ContextTypes.DEFAULT_TYPE, transactions: List[Dict]):
    """Process multiple transactions with confirmation."""
    user_id = update.effective_user.id
    chat_id = update.effective_chat.id
    
    confirmation_message = f"📝 *{len(transactions)} Transaksi Terdeteksi*\n\n"
    
    processed_transactions = []
    for i, transaction in enumerate(transactions, 1):
        processed_transaction = {
            'amount': float(transaction.get('amount', 0)),
            'category': str(transaction.get('category', 'Lainnya')),
            'description': str(transaction.get('description', f'Transaksi {i}')),
            'date': str(transaction.get('date', today()))
        }
        processed_transactions.append(processed_transaction)
        
        txn_type = "Pemasukan" if processed_transaction['amount'] > 0 else "Pengeluaran"
        safe_description = escape_markdown(processed_transaction['description'][:50])
        confirmation_message += f"*Transaksi {i}:*\n"
        confirmation_message += f"📅 Tanggal: {processed_transaction['date']}\n"
        confirmation_message += f"📊 Jenis: {txn_type}\n"
        confirmation_message += f"💰 Jumlah: {format_rupiah(abs(processed_transaction['amount']))}\n"
        confirmation_message += f"🏷️ Kategori: {processed_transaction['category']}\n"
        confirmation_message += f"📄 Deskripsi: {safe_description}\n\n"
    
    confirmation_message += "Apakah semua transaksi ini benar?"
    
    context.user_data['pending_multiple_transactions'] = processed_transactions
    
    keyboard = [
        [InlineKeyboardButton("✅ Benar Semua", callback_data="confirm_all_yes"),
         InlineKeyboardButton("❌ Batal", callback_data="confirm_all_no")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(confirmation_message, reply_markup=reply_markup, parse_mode='Markdown')


async def multiple_transactions_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle multiple transactions confirmation."""
    query = update.callback_query
    user_id = update.effective_user.id
    chat_id = update.effective_chat.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    
    if query.data == "confirm_all_yes":
        transactions = context.user_data.get('pending_multiple_transactions', [])
        if not transactions:
            await query.edit_message_text("❌ Tidak ada transaksi.")
            return
        
        if not settings.USE_GOOGLE_SHEETS:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        try:
            gs = get_google_sheets()
            if not gs or not gs.is_initialized:
                await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
                return
            
            success_count = 0
            for transaction in transactions:
                try:
                    txn = Transaction(
                        date=transaction.get('date', today()),
                        amount=transaction.get('amount', 0),
                        category=transaction.get('category', 'Lainnya'),
                        description=transaction.get('description', ''),
                        user_id=str(user_id)
                    )
                    if gs.add_transaction(txn):
                        success_count += 1
                    await asyncio.sleep(0.2)
                except Exception as e:
                    logger.error(f"Error recording transaction: {e}")
            
            if success_count > 0:
                PNLManager.update_pnl(str(user_id))
            else:
                PNLManager.clear_pnl(str(user_id))
            
            context.user_data.pop('pending_multiple_transactions', None)
            
            # ============================================================
            # JADWALKAN HAPUS PESAN 3 DETIK
            # ============================================================
            try:
                schedule_delete_messages(context, chat_id, user_id)
            except Exception as e:
                logger.warning(f"Gagal schedule delete: {e}")
            
            await query.edit_message_text(
                f"✅ {success_count} dari {len(transactions)} transaksi berhasil dicatat!\n\n"
                f"Gunakan /dashboard untuk melihat ringkasan."
            )
            
        except Exception as e:
            logger.error(f"Error processing multiple transactions: {e}", exc_info=True)
            await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
        
    elif query.data == "confirm_all_no":
        context.user_data.pop('pending_multiple_transactions', None)
        await query.edit_message_text("❌ Dibatalkan.")
