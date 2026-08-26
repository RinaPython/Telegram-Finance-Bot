"""Receipt scanning handlers — SEMUA PESAN BAHASA INDONESIA"""

import io
import asyncio
from datetime import datetime
from PIL import Image
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes

from src.config.settings import settings
from src.utils.logger import logger
from src.utils.formatters import format_rupiah, escape_markdown
from src.services.google_sheets import get_google_sheets
from src.services.gemini_ai import gemini_service
from src.services.pnl_manager import PNLManager
from src.models.transaction import Transaction
from src.utils.timezone import today, get_timestamp


async def photo_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle photo messages (receipts)."""
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.is_gemini_enabled():
        await update.message.reply_text(
            "⚠️ Fitur scan struk tidak tersedia.\n\n"
            "💡 Silakan catat transaksi manual dengan format:\n"
            "'Beli makan 50000'"
        )
        return
    
    processing_msg = await update.message.reply_text(
        "🔍 Sedang menganalisis struk...\nMohon tunggu sebentar."
    )
    
    try:
        photo_file = await update.message.photo[-1].get_file()
        photo_bytes = await photo_file.download_as_bytearray()
        image = Image.open(io.BytesIO(photo_bytes))
        
        receipt_data = await gemini_service.analyze_receipt(image)
        
        if receipt_data.get('error'):
            error_msg = receipt_data.get('error')
            
            # ============================================================
            # PESAN ERROR BAHASA INDONESIA
            # ============================================================
            if 'quota' in error_msg.lower() or '429' in error_msg:
                await processing_msg.edit_text(
                    "❌ *Kuota Gemini Habis* 📊\n\n"
                    "Kuota harian untuk scan struk sudah habis.\n"
                    "Silakan tunggu hingga besok atau catat manual.\n\n"
                    "💡 *Catat Manual:*\n"
                    "Kirim pesan seperti:\n"
                    "• `Beli makan 50000`\n"
                    "• `Terima gaji 5000000`\n\n"
                    "🔄 Kuota akan reset otomatis besok.",
                    parse_mode='Markdown'
                )
            else:
                await processing_msg.edit_text(
                    f"❌ *Gagal Scan Struk*\n\n"
                    f"{error_msg}\n\n"
                    "💡 Tips:\n"
                    "• Pastikan foto struk jelas\n"
                    "• Atau catat manual: 'Beli makan 50000'",
                    parse_mode='Markdown'
                )
            return
        
        if receipt_data.get('items') and len(receipt_data['items']) > 0:
            await process_receipt_items(update, context, receipt_data, processing_msg)
        elif receipt_data.get('total_amount'):
            await process_receipt_total(update, context, receipt_data, processing_msg)
        else:
            await processing_msg.edit_text(
                "❌ *Tidak Dapat Mendeteksi Transaksi*\n\n"
                "💡 Tips:\n"
                "• Foto struk harus jelas dan terang\n"
                "• Pastikan struk tidak terpotong\n"
                "• Atau catat manual: 'Beli makan 50000'",
                parse_mode='Markdown'
            )
            
    except Exception as e:
        logger.error(f"Error processing photo: {e}", exc_info=True)
        await processing_msg.edit_text(
            "❌ *Terjadi Kesalahan*\n\n"
            "Gagal memproses foto.\n"
            "Silakan coba lagi atau catat manual.\n\n"
            "💡 Contoh: `Beli makan 50000`",
            parse_mode='Markdown'
        )


async def process_receipt_items(update: Update, context: ContextTypes.DEFAULT_TYPE, receipt_data: dict, processing_msg):
    """Process receipt with multiple items."""
    user_id = update.effective_user.id
    
    store_name = receipt_data.get('store_name') or 'Toko'
    receipt_date = receipt_data.get('receipt_date') or today()
    total_amount = receipt_data.get('total_amount') or 0
    
    safe_store_name = escape_markdown(str(store_name)) if store_name else 'Toko'
    
    confirmation_message = f"🧾 *Struk dari {safe_store_name}*\n"
    confirmation_message += f"📅 Tanggal: {receipt_date}\n"
    confirmation_message += f"💰 Total: {format_rupiah(abs(total_amount))}\n\n"
    
    confirmation_message += "*Detail Barang:*\n"
    items = receipt_data.get('items', [])
    if items:
        for i, item in enumerate(items[:10], 1):
            item_desc = item.get('description') or 'Item'
            item_amount = float(item.get('amount') or 0)
            confirmation_message += f"{i}. {escape_markdown(str(item_desc))}: {format_rupiah(abs(item_amount))}\n"
    else:
        confirmation_message += "Tidak ada item yang terdeteksi.\n"
    
    if len(items) > 10:
        confirmation_message += f"... dan {len(items) - 10} item lainnya\n"
    
    confirmation_message += "\nPilih cara pencatatan:"
    
    context.user_data['pending_receipt'] = receipt_data
    
    keyboard = [
        [InlineKeyboardButton("💵 Catat Total", callback_data="receipt_total")],
        [InlineKeyboardButton("📝 Catat Per Item", callback_data="receipt_items")],
        [InlineKeyboardButton("🏷️ Catat Per Kategori", callback_data="receipt_categories")],
        [InlineKeyboardButton("❌ Batal", callback_data="receipt_cancel")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await processing_msg.edit_text(
        confirmation_message,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


async def process_receipt_total(update: Update, context: ContextTypes.DEFAULT_TYPE, receipt_data: dict, processing_msg):
    """Process receipt with only total amount."""
    user_id = update.effective_user.id
    
    total_amount = -abs(float(receipt_data.get('total_amount') or 0))
    store_name = receipt_data.get('store_name') or 'Toko'
    receipt_date = receipt_data.get('receipt_date') or today()
    description = receipt_data.get('suggested_description') or f'Belanja di {store_name}'
    
    safe_store_name = escape_markdown(str(store_name)) if store_name else 'Toko'
    safe_description = escape_markdown(str(description)) if description else 'Belanja'
    
    confirmation_message = f"📝 *Detail Transaksi*\n\n"
    confirmation_message += f"📅 Tanggal: {receipt_date}\n"
    confirmation_message += f"🏪 Toko: {safe_store_name}\n"
    confirmation_message += f"📊 Jenis: Pengeluaran\n"
    confirmation_message += f"💰 Jumlah: {format_rupiah(abs(total_amount))}\n"
    confirmation_message += f"🏷️ Kategori: Belanja\n"
    confirmation_message += f"📄 Deskripsi: {safe_description}\n\n"
    confirmation_message += "Apakah data ini benar?"
    
    context.user_data['pending_transaction'] = {
        'date': receipt_date,
        'amount': total_amount,
        'category': 'Belanja',
        'description': description
    }
    
    keyboard = [
        [InlineKeyboardButton("✅ Ya", callback_data="confirm_yes"),
         InlineKeyboardButton("✏️ Edit", callback_data="confirm_edit")],
        [InlineKeyboardButton("🚫 Batal", callback_data="confirm_cancel")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await processing_msg.edit_text(
        confirmation_message,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


async def receipt_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle receipt processing callbacks."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    action = query.data.split("_")[1]
    
    if action == "cancel":
        await query.edit_message_text("❌ Pencatatan struk dibatalkan.")
        context.user_data.pop('pending_receipt', None)
        return
    
    receipt_data = context.user_data.get('pending_receipt', {})
    if not receipt_data:
        await query.edit_message_text("❌ Data struk tidak ditemukan.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    try:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        if action == "total":
            amount = -abs(float(receipt_data.get('total_amount') or 0))
            store_name = receipt_data.get('store_name') or 'Toko'
            receipt_date = receipt_data.get('receipt_date') or today()
            description = receipt_data.get('suggested_description') or f'Belanja di {store_name}'
            
            safe_store_name = escape_markdown(str(store_name)) if store_name else 'Toko'
            
            txn = Transaction(
                date=receipt_date,
                amount=amount,
                category='Belanja',
                description=description,
                user_id=str(user_id)
            )
            
            if gs.add_transaction(txn):
                PNLManager.update_pnl(str(user_id))
                await query.edit_message_text(
                    f"✅ Transaksi berhasil dicatat!\n\n"
                    f"💰 Total: {format_rupiah(abs(amount))}\n"
                    f"🏪 Toko: {safe_store_name}\n"
                    f"📅 Tanggal: {receipt_date}"
                )
            else:
                await query.edit_message_text("⚠️ Gagal menyimpan transaksi.")
            
        elif action == "items":
            items = receipt_data.get('items', [])
            receipt_date = receipt_data.get('receipt_date') or today()
            store_name = receipt_data.get('store_name') or 'Toko'
            
            safe_store_name = escape_markdown(str(store_name)) if store_name else 'Toko'
            
            success_count = 0
            for item in items:
                try:
                    item_amount = -abs(float(item.get('amount') or 0))
                    item_desc = item.get('description') or 'Item'
                    item_category = item.get('category') or 'Belanja'
                    
                    txn = Transaction(
                        date=receipt_date,
                        amount=item_amount,
                        category=item_category,
                        description=f"{item_desc} di {store_name}",
                        user_id=str(user_id)
                    )
                    if gs.add_transaction(txn):
                        success_count += 1
                    await asyncio.sleep(0.2)
                except Exception as e:
                    logger.error(f"Error recording item: {e}")
            
            PNLManager.update_pnl(str(user_id))
            await query.edit_message_text(
                f"✅ {success_count} item berhasil dicatat!\n"
                f"🏪 {safe_store_name}\n"
                f"📅 {receipt_date}"
            )
            
        elif action == "categories":
            items = receipt_data.get('items', [])
            receipt_date = receipt_data.get('receipt_date') or today()
            store_name = receipt_data.get('store_name') or 'Toko'
            
            safe_store_name = escape_markdown(str(store_name)) if store_name else 'Toko'
            
            category_totals = {}
            for item in items:
                category = item.get('category') or 'Belanja'
                amount = abs(float(item.get('amount') or 0))
                category_totals[category] = category_totals.get(category, 0) + amount
            
            success_count = 0
            for category, total in category_totals.items():
                try:
                    txn = Transaction(
                        date=receipt_date,
                        amount=-total,
                        category=category,
                        description=f"Belanja {category} di {store_name}",
                        user_id=str(user_id)
                    )
                    if gs.add_transaction(txn):
                        success_count += 1
                    await asyncio.sleep(0.2)
                except Exception as e:
                    logger.error(f"Error recording category: {e}")
            
            PNLManager.update_pnl(str(user_id))
            await query.edit_message_text(
                f"✅ {success_count} kategori berhasil dicatat!\n"
                f"🏪 {safe_store_name}\n"
                f"📅 {receipt_date}"
            )
        
        context.user_data.pop('pending_receipt', None)
        
    except Exception as e:
        logger.error(f"Error processing receipt: {e}", exc_info=True)
        await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
