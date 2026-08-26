"""Command handlers for the bot — BAHASA INDONESIA"""

from datetime import datetime
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, ReplyKeyboardMarkup, KeyboardButton
from telegram.ext import ContextTypes

from src.config.settings import settings
from src.config.constants import STATE_WAITING_AMOUNT
from src.utils.logger import logger
from src.utils.formatters import format_rupiah, get_category_emoji, escape_markdown
from src.services.google_sheets import get_google_sheets
from src.services.financial_analytics import FinancialAnalytics
from src.services.pnl_manager import PNLManager
from src.utils.timezone import now, today, get_timestamp
from src.handlers.transaction import schedule_delete_messages


def get_main_keyboard():
    """Create persistent keyboard menu."""
    keyboard = [
        [KeyboardButton("💳 Catat Transaksi"), KeyboardButton("📊 Dashboard")],
        [KeyboardButton("📈 Profit & Loss"), KeyboardButton("📋 Riwayat")],
        [KeyboardButton("🗑️ Hapus Data"), KeyboardButton("📑 Google Sheets")],
        [KeyboardButton("⚙️ Pengaturan")]
    ]
    return ReplyKeyboardMarkup(
        keyboard,
        resize_keyboard=True,
        is_persistent=True,
        one_time_keyboard=False
    )


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /start command - langsung tampilkan keyboard menu."""
    user_id = update.effective_user.id
    user_name = update.effective_user.first_name or "Pengguna"
    
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    safe_name = escape_markdown(user_name)
    
    welcome_text = (
        f"💼 *Selamat datang, {safe_name}!*\n\n"
        "Saya akan membantu Anda mencatat dan mengelola keuangan pribadi.\n\n"
        "📌 *Yang bisa saya lakukan:*\n"
        "• Mencatat pemasukan dan pengeluaran\n"
        "• Menampilkan *DASHBOARD* keuangan\n"
        "• Menghitung *PROFIT & LOSS*\n"
        "• Menyimpan data ke *Google Sheets*\n"
        "• Memberikan insight keuangan\n\n"
        "👇 *Pilih menu di bawah untuk memulai*"
    )
    
    await update.message.reply_text(
        welcome_text,
        parse_mode='Markdown',
        reply_markup=get_main_keyboard()
    )


async def menu_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show main menu with persistent keyboard."""
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    menu_text = (
        "📋 *MENU UTAMA*\n\n"
        "Pilih salah satu opsi di bawah ini:\n\n"
        "💳 *Catat Transaksi* — Tambahkan pemasukan atau pengeluaran\n"
        "📊 *Dashboard* — Lihat ringkasan keuangan\n"
        "📈 *Profit & Loss* — Analisis laba dan rugi\n"
        "📋 *Riwayat* — Lihat transaksi terakhir\n"
        "🗑️ *Hapus Data* — Hapus transaksi yang tidak diperlukan\n"
        "📑 *Google Sheets* — Buka spreadsheet data\n"
        "⚙️ *Pengaturan* — Atur preferensi bot"
    )
    await update.message.reply_text(
        menu_text,
        parse_mode='Markdown',
        reply_markup=get_main_keyboard()
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    help_text = (
        "📖 *PANDUAN PENGGUNAAN*\n\n"
        "📌 *Mencatat Transaksi*\n"
        "Kirim pesan dengan format: `[deskripsi] [jumlah]`\n"
        "Contoh: `Beli makan siang 50000`\n\n"
        "📸 *Scan Struk*\n"
        "Kirim foto struk untuk scan otomatis\n\n"
        "📋 *Multi-Transaksi*\n"
        "Kirim beberapa baris sekaligus\n\n"
        "📊 *Dashboard*\n"
        "Lihat ringkasan keuangan lengkap\n\n"
        "📈 *Profit & Loss*\n"
        "Analisis keuangan mendalam\n\n"
        "📑 *Google Sheets*\n"
        "Akses semua data di spreadsheet\n\n"
        "⚙️ *Daftar Perintah*\n"
        "`/start` — Menu utama\n"
        "`/catat` — Catat transaksi\n"
        "`/dashboard` — Dashboard\n"
        "`/pnl` — Profit & Loss\n"
        "`/riwayat` — Riwayat\n"
        "`/laporan` — Laporan\n"
        "`/sheet` — Google Sheets\n"
        "`/hapus` — Hapus data\n"
        "`/pengaturan` — Pengaturan"
    )
    await update.message.reply_text(help_text, parse_mode='Markdown')


async def me_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    await update.message.reply_text(f"🆔 ID Pengguna: `{user_id}`", parse_mode='Markdown')


async def record_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    await update.message.reply_text(
        "💳 *Catat Transaksi*\n\n"
        "Kirim detail transaksi.\n\n"
        "*Format:* [deskripsi] [jumlah]\n\n"
        "*Contoh:*\n"
        "• Beli makan siang 50000\n"
        "• Terima gaji 5000000\n"
        "• Bayar listrik 350000\n\n"
        "📸 *Atau kirim foto struk* untuk scan otomatis!\n\n"
        "💡 Kirim beberapa baris sekaligus untuk multi-transaksi.\n\n"
        "🗑️ *Pesan otomatis dihapus 3 detik setelah transaksi.*",
        parse_mode='Markdown'
    )


async def delete_data(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    keyboard = [
        [InlineKeyboardButton("🗑️ Hapus Terakhir", callback_data="delete_last")],
        [InlineKeyboardButton("📅 Hapus Berdasarkan Tanggal", callback_data="delete_date")],
        [InlineKeyboardButton("🗑️ Hapus Semua", callback_data="delete_all")],
        [InlineKeyboardButton("❌ Batal", callback_data="delete_cancel")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        "🗑️ *HAPUS DATA*\n\n"
        "⚠️ Data yang dihapus *tidak dapat dikembalikan!*\n\n"
        "Pilih opsi di bawah ini:",
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


async def sheet_link_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    if not settings.USE_GOOGLE_SHEETS:
        await update.message.reply_text("⚠️ Google Sheets tidak terhubung.")
        return
    
    spreadsheet_url = f"https://docs.google.com/spreadsheets/d/{settings.get_spreadsheet_id()}"
    keyboard = [[InlineKeyboardButton("📑 Buka Google Sheets", url=spreadsheet_url)]]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        "📑 *GOOGLE SHEETS*\n\n"
        "Semua data keuangan Anda tersimpan di spreadsheet.\n\n"
        "📌 *Akses data:*\n"
        "• Lihat semua transaksi\n"
        "• Ekspor ke Excel/CSV\n"
        "• Buat grafik sendiri\n"
        "• Analisis data lebih dalam\n\n"
        "🔗 Klik tombol di bawah untuk membuka Google Sheets.",
        parse_mode='Markdown',
        reply_markup=reply_markup,
        disable_web_page_preview=True
    )


async def settings_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    auto_delete = context.user_data.get('delete_messages', settings.DELETE_MESSAGES)
    
    settings_text = (
        "⚙️ *PENGATURAN*\n\n"
        f"🗑️ *Hapus pesan otomatis:* {'✅ Aktif' if auto_delete else '❌ Nonaktif'}\n\n"
        "📌 *Pilih opsi di bawah ini:*"
    )
    
    keyboard = [
        [InlineKeyboardButton("✅ Aktifkan" if not auto_delete else "❌ Nonaktifkan", callback_data="settings_toggle_delete")],
        [InlineKeyboardButton("🔄 Perbarui PNL", callback_data="settings_update_pnl")],
        [InlineKeyboardButton("📊 Segarkan Data", callback_data="settings_refresh")],
        [InlineKeyboardButton("❌ Tutup", callback_data="settings_close")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        settings_text,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


async def toggle_delete_messages(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if not settings.is_authorized(user_id):
        await update.message.reply_text("⛔ Maaf, Anda tidak memiliki akses.")
        return
    
    current = context.user_data.get('delete_messages', settings.DELETE_MESSAGES)
    context.user_data['delete_messages'] = not current
    status = "aktif" if context.user_data['delete_messages'] else "nonaktif"
    
    await update.message.reply_text(
        f"🗑️ Penghapusan pesan otomatis: *{status.upper()}*\n\n"
        f"{'Pesan akan dihapus otomatis 3 detik setelah transaksi.' if context.user_data['delete_messages'] else 'Pesan tidak akan dihapus otomatis.'}",
        parse_mode='Markdown'
    )


async def settings_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    
    if query.data == "settings_close":
        await query.edit_message_text("⚙️ Pengaturan ditutup.")
        return
    
    if query.data == "settings_toggle_delete":
        current = context.user_data.get('delete_messages', settings.DELETE_MESSAGES)
        context.user_data['delete_messages'] = not current
        status = "aktif" if context.user_data['delete_messages'] else "nonaktif"
        await query.edit_message_text(f"✅ Penghapusan pesan otomatis telah di{status}kan.")
        return
    
    if query.data == "settings_update_pnl":
        await query.edit_message_text("🔄 Memperbarui PNL...")
        try:
            success = PNLManager.update_pnl(str(user_id))
            if success:
                await query.edit_message_text("✅ PNL berhasil diperbarui!")
            else:
                await query.edit_message_text("⚠️ Gagal memperbarui PNL.")
        except Exception as e:
            logger.error(f"Error updating PNL: {e}", exc_info=True)
            await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
        return
    
    if query.data == "settings_refresh":
        await query.edit_message_text("🔄 Menyegarkan data...")
        try:
            success = PNLManager.update_pnl(str(user_id))
            if success:
                await query.edit_message_text("✅ Data berhasil disegarkan!")
            else:
                await query.edit_message_text("⚠️ Data berhasil disegarkan sebagian.")
        except Exception as e:
            logger.error(f"Error refreshing: {e}", exc_info=True)
            await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
        return


async def menu_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle menu callbacks from inline keyboard."""
    query = update.callback_query
    user_id = update.effective_user.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    action = query.data.replace("menu_", "")
    
    if action == "catat":
        await query.edit_message_text(
            "💳 *Catat Transaksi*\n\n"
            "Kirim pesan dengan detail transaksi.\n\n"
            "*Contoh:*\n"
            "• Beli makan siang 50000\n"
            "• Terima gaji 5000000\n\n"
            "📸 *Atau kirim foto struk* untuk scan otomatis!\n\n"
            "💡 Kirim beberapa baris sekaligus untuk multi-transaksi.",
            parse_mode='Markdown'
        )
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "dashboard":
        from src.handlers.financial import dashboard_command_from_callback
        await dashboard_command_from_callback(update, context)
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "pnl":
        from src.handlers.financial import pnl_command_from_callback
        await pnl_command_from_callback(update, context)
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "riwayat":
        from src.handlers.financial import history_command_from_callback
        await history_command_from_callback(update, context)
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "laporan":
        from src.handlers.financial import report_command
        await report_command(update, context)
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "hapus":
        await delete_data(update, context)
    
    elif action == "sheet":
        await sheet_link_command(update, context)
        await query.message.reply_text(
            "Kembali ke menu:",
            reply_markup=get_main_keyboard()
        )
    
    elif action == "settings":
        await settings_command(update, context)


# ============================================================
# BUTTON_CALLBACK — LENGKAP DENGAN AUTO DELETE 3 DETIK
# ============================================================

async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle all button callbacks for transactions — dengan auto delete 3 detik."""
    query = update.callback_query
    user_id = update.effective_user.id
    chat_id = update.effective_chat.id
    
    if not settings.is_authorized(user_id):
        await query.answer("Anda tidak memiliki akses.", show_alert=True)
        return
    
    await query.answer()
    
    # ============================================================
    # EDIT TEXT HANDLER
    # ============================================================
    if query.data == "edit_text":
        await query.edit_message_text(
            "✏️ *Edit Teks Transaksi*\n\n"
            "Kirim ulang detail transaksi dengan format:\n"
            "`[deskripsi] [jumlah]`\n\n"
            "Contoh:\n"
            "• `Beli makan siang 50000`\n"
            "• `Terima gaji 5000000`\n\n"
            "Atau kirim 'batal' untuk membatalkan.",
            parse_mode='Markdown'
        )
        context.user_data['waiting_edit_text'] = True
        return
    
    # Transaction type selection
    if query.data.startswith("type_"):
        transaction_type = query.data.split("_")[1]
        message_text = context.user_data.get('pending_message', '')
        detected_date = context.user_data.get('detected_date', today())
        
        context.user_data['transaction_type'] = transaction_type
        context.user_data['description'] = message_text
        context.user_data['date'] = detected_date
        context.user_data['conversation_state'] = STATE_WAITING_AMOUNT
        
        safe_description = escape_markdown(message_text)
        
        await query.edit_message_text(
            f"📅 Tanggal: {detected_date}\n"
            f"📝 Deskripsi: {safe_description}\n"
            f"📊 Jenis: {'Pemasukan' if transaction_type == 'income' else 'Pengeluaran'}\n\n"
            f"💰 Berapa jumlahnya?\n\n"
            f"_Contoh: 50000, 50k, 50rb, 1jt_",
            parse_mode='Markdown'
        )
        return
    
    # ============================================================
    # CONFIRMATION HANDLER — DENGAN AUTO DELETE 3 DETIK
    # ============================================================
    if query.data.startswith("confirm_"):
        action = query.data.split("_", 1)[1]
        
        if action.startswith("all_"):
            return
        
        if action == "yes":
            transaction = context.user_data.get('pending_transaction', {})
            if not transaction:
                await query.edit_message_text("❌ Tidak ada data transaksi.")
                return
            
            if not settings.USE_GOOGLE_SHEETS:
                await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
                return
            
            try:
                from src.models.transaction import Transaction
                from src.services.google_sheets import get_google_sheets
                
                gs = get_google_sheets()
                if not gs or not gs.is_initialized:
                    await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
                    return
                
                txn = Transaction(
                    date=transaction.get('date', today()),
                    amount=transaction.get('amount', 0),
                    category=transaction.get('category', 'Lainnya'),
                    description=transaction.get('description', ''),
                    user_id=str(user_id)
                )
                
                if gs.add_transaction(txn):
                    PNLManager.update_pnl(str(user_id))
                    amount = transaction.get('amount', 0)
                    txn_type = "Pemasukan" if amount > 0 else "Pengeluaran"
                    safe_description = escape_markdown(transaction.get('description', ''))
                    
                    await query.edit_message_text(
                        f"✅ Transaksi berhasil dicatat!\n\n"
                        f"📊 Jenis: {txn_type}\n"
                        f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
                        f"🏷️ Kategori: {transaction.get('category', 'Lainnya')}\n"
                        f"📄 Deskripsi: {safe_description}",
                        parse_mode='Markdown'
                    )
                    
                    # ============================================================
                    # JADWALKAN HAPUS PESAN 3 DETIK
                    # ============================================================
                    try:
                        from src.handlers.transaction import schedule_delete_messages
                        schedule_delete_messages(context, chat_id, user_id)
                    except Exception as e:
                        logger.warning(f"Gagal schedule delete: {e}")
                    
                    # Hapus semua data pending
                    for key in ['pending_transaction', 'pending_message', 'transaction_type', 
                               'description', 'detected_date', 'conversation_state', 
                               'pending_category', 'date']:
                        context.user_data.pop(key, None)
                else:
                    await query.edit_message_text("⚠️ Gagal menyimpan transaksi.")
                    
            except Exception as e:
                logger.error(f"Error saving: {e}", exc_info=True)
                await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
            return
        
        elif action in ("no", "edit"):
            pending_message = context.user_data.get('pending_message')
            pending_transaction = context.user_data.get('pending_transaction')
            
            context.user_data.pop('conversation_state', None)
            
            if pending_message or pending_transaction:
                keyboard = [
                    [InlineKeyboardButton("💰 Pemasukan", callback_data="type_income"),
                     InlineKeyboardButton("💸 Pengeluaran", callback_data="type_expense")],
                    [InlineKeyboardButton("✏️ Edit Teks", callback_data="edit_text")],
                    [InlineKeyboardButton("❌ Batal", callback_data="confirm_cancel")]
                ]
                reply_markup = InlineKeyboardMarkup(keyboard)
                
                teks = pending_message if pending_message else "Transaksi"
                await query.edit_message_text(
                    f"📝 *Edit Transaksi*\n\n"
                    f"📄 Teks: `{escape_markdown(teks[:100])}`\n\n"
                    f"Pilih opsi di bawah ini:",
                    reply_markup=reply_markup,
                    parse_mode='Markdown'
                )
            else:
                await query.edit_message_text(
                    "ℹ️ *Tidak Ada Transaksi yang Bisa Diedit*\n\n"
                    "Transaksi sudah tersimpan atau tidak ada data yang sedang diproses.\n\n"
                    "💡 Silakan catat transaksi baru dengan mengirim pesan seperti:\n"
                    "• `Beli makan 50000`\n"
                    "• `Terima gaji 5000000`",
                    parse_mode='Markdown'
                )
            return
        
        elif action == "cancel":
            for key in ['pending_transaction', 'pending_message', 'transaction_type', 
                       'amount', 'description', 'detected_date', 'pending_receipt', 
                       'conversation_state', 'pending_category', 'date']:
                context.user_data.pop(key, None)
            await query.edit_message_text("✅ Pencatatan dibatalkan.")
            return
    
    # Category selection
    if query.data.startswith("cat_"):
        category = query.data.split("_")[1]
        amount = context.user_data.get('amount', 0)
        description = context.user_data.get('description', '')
        
        if not settings.USE_GOOGLE_SHEETS:
            await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
            return
        
        try:
            from src.models.transaction import Transaction
            from src.services.google_sheets import get_google_sheets
            
            gs = get_google_sheets()
            if not gs or not gs.is_initialized:
                await query.edit_message_text("⚠️ Google Sheets tidak terhubung.")
                return
            
            txn = Transaction(
                date=today(),
                amount=amount,
                category=category,
                description=description,
                user_id=str(user_id)
            )
            
            if gs.add_transaction(txn):
                PNLManager.update_pnl(str(user_id))
                txn_type = "Pemasukan" if amount > 0 else "Pengeluaran"
                safe_description = escape_markdown(description)
                
                await query.edit_message_text(
                    f"✅ Transaksi berhasil dicatat!\n\n"
                    f"📊 Jenis: {txn_type}\n"
                    f"💰 Jumlah: {format_rupiah(abs(amount))}\n"
                    f"🏷️ Kategori: {category}\n"
                    f"📄 Deskripsi: {safe_description}",
                    parse_mode='Markdown'
                )
                
                # ============================================================
                # JADWALKAN HAPUS PESAN 3 DETIK
                # ============================================================
                try:
                    from src.handlers.transaction import schedule_delete_messages
                    schedule_delete_messages(context, chat_id, user_id)
                except Exception as e:
                    logger.warning(f"Gagal schedule delete: {e}")
                
                context.user_data.clear()
            else:
                await query.edit_message_text("⚠️ Gagal menyimpan transaksi.")
            
        except Exception as e:
            logger.error(f"Error saving category: {e}", exc_info=True)
            await query.edit_message_text("⚠️ Maaf, terjadi kendala.")
