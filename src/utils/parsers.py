"""Parsing utilities for financial data — FIXED EXPENSE DETECTION & CACHE"""

import re
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from src.config.constants import INCOME_KEYWORDS, EXPENSE_KEYWORDS, CATEGORY_MAP
from src.utils.timezone import now, today, yesterday, tomorrow, JAKARTA_TZ


# ============================================================
# CACHE UNTUK LOCAL PARSER (OPTIMASI KECEPATAN)
# ============================================================
_local_cache = {}
_local_cache_max = 50


def parse_indonesian_amount(text: str) -> Optional[float]:
    """
    Parse Indonesian number formats locally without AI.
    Supports: 70k, 70K, 50rb, 50ribu, 1jt, 1juta, 1.5jt, 1,5jt, dll.
    """
    text = text.lower().strip()

    # Handle format 16,4jt / 16.4jt
    match = re.search(r'(\d+)[,.](\d+)\s*(?:juta|jt)', text)
    if match:
        whole = int(match.group(1))
        decimal = int(match.group(2))
        if decimal < 10:
            amount = (whole + decimal / 10) * 1000000
        else:
            amount = (whole + decimal / 100) * 1000000
        return amount
    
    match = re.search(r'(\d+)[,.](\d+)\s*(?:ribu|rb|k)', text)
    if match:
        whole = int(match.group(1))
        decimal = int(match.group(2))
        if decimal < 10:
            amount = (whole + decimal / 10) * 1000
        else:
            amount = (whole + decimal / 100) * 1000
        return amount
    
    patterns = [
        (r'(\d+(?:[.,]\d+)?)\s*(?:juta|jt)', 1000000),
        (r'(\d+(?:[.,]\d+)?)\s*(?:ribu|rb|k)', 1000),
        (r'(\d{1,3}(?:[.,]\d{3})+)', 1),
        (r'(\d+)', 1),
    ]

    for pattern, multiplier in patterns:
        match = re.search(pattern, text)
        if match:
            num_str = match.group(1)
            if '.' in num_str and num_str.count('.') > 1:
                num_str = num_str.replace('.', '')
            elif ',' in num_str and num_str.count(',') > 1:
                num_str = num_str.replace(',', '')
            elif '.' in num_str or ',' in num_str:
                num_str = num_str.replace(',', '.')
            if '.' in num_str and num_str.count('.') == 1:
                num_str = num_str.replace('.', '')

            try:
                amount = float(num_str) * multiplier
                return amount
            except ValueError:
                continue

    return None


def parse_transaction_locally(text: str) -> Dict[str, Any]:
    """
    Parse transaction data locally without AI - DENGAN CACHE.
    """
    global _local_cache
    
    # ============================================================
    # CEK CACHE DULU
    # ============================================================
    if text in _local_cache:
        # Kembalikan copy agar tidak dimodifikasi
        return _local_cache[text].copy()
    
    # ============================================================
    # PROSES PARSING
    # ============================================================
    result = _parse_transaction_locally_impl(text)
    
    # ============================================================
    # SIMPAN KE CACHE
    # ============================================================
    if len(_local_cache) >= _local_cache_max:
        # Hapus 20% cache tertua
        keys = list(_local_cache.keys())
        for key in keys[:10]:
            del _local_cache[key]
    _local_cache[text] = result.copy()
    
    return result


def _parse_transaction_locally_impl(text: str) -> Dict[str, Any]:
    """
    Implementasi parsing transaksi lokal.
    """
    text_lower = text.lower()
    current_date = now()

    amount = parse_indonesian_amount(text)

    # ============================================================
    # DETEKSI EXPENSE — PRIORITAS UTAMA
    # ============================================================
    
    # Daftar kata yang PASTI expense (WAJIB)
    expense_force_words = [
        'beli', 'bayar', 'belanja', 'pengeluaran', 'keluar',
        'makan', 'minum', 'snack', 'jajan', 'makanan', 'minuman',
        'modal', 'investasi', 'bisnis', 'usaha',
        'tagihan', 'listrik', 'air', 'pulsa', 'internet', 'gas',
        'bensin', 'parkir', 'tol', 'ojek', 'grab', 'gojek', 'taxi',
        'obat', 'dokter', 'rumah sakit', 'klinik', 'apotek',
        'buku', 'kursus', 'les', 'sekolah', 'kuliah', 'spp',
        'sumbangan', 'donasi', 'zakat', 'infaq', 'sedekah',
        'sewa', 'booking', 'berlangganan', 'subscription',
        'transfer ke', 'kirim ke', 'buat', 'untuk',
        'makan', 'minum', 'jajan', 'snack',
    ]
    
    # Daftar kata yang PASTI income (WAJIB)
    income_force_words = [
        'gaji', 'bonus', 'komisi', 'dividen', 'bunga', 'hadiah',
        'warisan', 'penjualan', 'refund', 'kembalian', 'cashback',
        'terima', 'dapat', 'pemasukan', 'masuk', 'diterima',
        'pendapatan', 'profit', 'keuntungan', 'investasi', 'royalti',
        'sewa', 'penghasilan', 'upah', 'honor',
        'saldo', 'deposit', 'setor', 'tambah', 'tambahan', 'masukin'
    ]
    
    # ============================================================
    # CEK FORCE WORDS
    # ============================================================
    
    is_force_expense = False
    for word in expense_force_words:
        if word in text_lower:
            is_force_expense = True
            break
    
    is_force_income = False
    for word in income_force_words:
        if word in text_lower:
            is_force_income = True
            break
    
    # ============================================================
    # TENTUKAN TYPE — EXPENSE LEBIH PRIORITAS
    # ============================================================
    
    if is_force_expense:
        transaction_type = 'expense'
    elif is_force_income:
        transaction_type = 'income'
    else:
        # DEFAULT: expense (lebih aman)
        transaction_type = 'expense'

    # Determine category
    category = 'Lainnya'
    for cat, keywords in CATEGORY_MAP.items():
        if any(kw in text_lower for kw in keywords):
            category = cat.capitalize()
            break
    
    if 'modal' in text_lower:
        category = 'Bisnis'
    
    if any(kw in text_lower for kw in ['makan', 'minum', 'snack', 'jajan']):
        category = 'Makanan'

    # Parse date
    date = current_date.strftime("%Y-%m-%d")
    if 'kemarin' in text_lower or 'yesterday' in text_lower:
        date = (current_date - timedelta(days=1)).strftime("%Y-%m-%d")
    elif 'besok' in text_lower or 'tomorrow' in text_lower:
        date = (current_date + timedelta(days=1)).strftime("%Y-%m-%d")

    # ============================================================
    # DESKRIPSI HANYA KATA-KATA (TANPA NOMINAL)
    # ============================================================
    description = text
    if amount:
        description = re.sub(r'\d+(?:[.,]\d+)?\s*(?:juta|jt|ribu|rb|k)?', '', text, flags=re.IGNORECASE)
        description = re.sub(r'rp\.?\s*', '', description, flags=re.IGNORECASE)
        description = re.sub(r'[0-9,.\-]+', '', description)
        description = description.strip()
        
        if not description:
            if 'saldo' in text_lower:
                description = 'Saldo'
            elif 'gaji' in text_lower:
                description = 'Gaji'
            elif 'bonus' in text_lower:
                description = 'Bonus'
            elif 'makan' in text_lower:
                description = 'Makan'
            elif 'beli' in text_lower or 'belanja' in text_lower:
                description = 'Belanja'
            elif 'bayar' in text_lower or 'tagihan' in text_lower:
                description = 'Tagihan'
            elif 'modal' in text_lower:
                description = 'Modal'
            elif 'bisnis' in text_lower:
                description = 'Bisnis'
            else:
                description = 'Transaksi'

    if amount and transaction_type == 'expense':
        amount = -abs(amount)
    elif amount:
        amount = abs(amount)

    return {
        'amount': amount,
        'description': description,
        'transaction_type': transaction_type,
        'category': category,
        'date': date
    }


def parse_date_from_text(text: str) -> str:
    """Extract date from text using various methods."""
    current_date = now()
    text = text.lower()
    
    if "kemarin" in text or "yesterday" in text:
        return (current_date - timedelta(days=1)).strftime("%Y-%m-%d")
    elif "hari ini" in text or "today" in text:
        return current_date.strftime("%Y-%m-%d")
    elif "besok" in text or "tomorrow" in text:
        return (current_date + timedelta(days=1)).strftime("%Y-%m-%d")
    elif "lusa" in text:
        return (current_date + timedelta(days=2)).strftime("%Y-%m-%d")
    
    days_ago_match = re.search(r'(\d+)\s+hari\s+(?:yang\s+)?lalu', text) or re.search(r'(\d+)\s+days\s+ago', text)
    if days_ago_match:
        days = int(days_ago_match.group(1))
        return (current_date - timedelta(days=days)).strftime("%Y-%m-%d")
    
    date_patterns = [
        r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})',
        r'(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})'
    ]
    
    for pattern in date_patterns:
        match = re.search(pattern, text)
        if match:
            groups = match.groups()
            if len(groups[0]) == 4:
                year, month, day = groups
            else:
                day, month, year = groups
            try:
                date_obj = datetime(int(year), int(month), int(day), tzinfo=JAKARTA_TZ)
                return date_obj.strftime("%Y-%m-%d")
            except ValueError:
                continue
    
    return current_date.strftime("%Y-%m-%d")