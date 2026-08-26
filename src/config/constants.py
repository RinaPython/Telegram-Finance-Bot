"""Constants and mappings — Complete configuration"""

# ============================================================
# CATEGORY EMOJI MAPPING
# ============================================================

CATEGORY_EMOJIS = {
    'Makanan': '🍽️',
    'Protein': '🍗',
    'Sayur': '🥬',
    'Buah': '🍍',
    'Minuman': '🥤',
    'Snack': '🍿',
    'Bumbu': '🧄',
    'Roti': '🍞',
    'Nasi': '🍚',
    'Mie': '🍜',
    'Daging': '🥩',
    'Seafood': '🦐',
    'Susu': '🥛',
    'Transportasi': '🚗',
    'Bensin': '⛽',
    'Parkir': '🅿️',
    'Ojek': '🏍️',
    'Bus': '🚌',
    'Kereta': '🚊',
    'Tol': '🛣️',
    'Belanja': '🛒',
    'Pakaian': '👕',
    'Elektronik': '📱',
    'Kosmetik': '💄',
    'Perabotan': '🪑',
    'Kesehatan': '🏥',
    'Obat': '💊',
    'Vitamin': '💊',
    'Dokter': '👨‍⚕️',
    'Rumah Sakit': '🏥',
    'Tagihan': '🧾',
    'Listrik': '💡',
    'Air': '💧',
    'Internet': '📶',
    'Pulsa': '📞',
    'Gas': '🔥',
    'BPJS': '🛡️',
    'Hiburan': '🎬',
    'Bioskop': '🎭',
    'Game': '🎮',
    'Musik': '🎵',
    'Olahraga': '⚽',
    'Liburan': '🏖️',
    'Pendidikan': '📚',
    'Buku': '📖',
    'Kursus': '🎓',
    'Sekolah': '🏫',
    'Gaji': '💰',
    'Bonus': '🎁',
    'Investasi': '📈',
    'Hadiah': '🎉',
    'Penjualan': '💸',
    'Bisnis': '💼',
    'Dividen': '📊',
    'Bunga': '🏦',
    'Lainnya': '📦',
    'Unknown': '❓',
}

# ============================================================
# INCOME KEYWORDS
# ============================================================

INCOME_KEYWORDS = [
    'terima', 'dapat', 'pemasukan', 'masuk', 'diterima',
    'gaji', 'bonus', 'komisi', 'dividen', 'bunga', 'hadiah',
    'warisan', 'penjualan', 'refund', 'kembalian', 'cashback',
    'dibayar oleh', 'transfer dari', 'kiriman dari', 'diberi', 'dikasih',
    'pendapatan', 'profit', 'keuntungan', 'saham', 'investasi',
    'royalti', 'sewa', 'penghasilan', 'upah', 'honor',
    'saldo', 'deposit', 'setor', 'tambah', 'tambahan', 'masukin',
]

# ============================================================
# EXPENSE KEYWORDS — TAMBAHKAN "MODAL"
# ============================================================

EXPENSE_KEYWORDS = [
    'beli', 'bayar', 'belanja', 'pengeluaran', 'keluar', 'dibayar',
    'membeli', 'memesan', 'berlangganan', 'sewa', 'booking',
    'makanan', 'transportasi', 'bensin', 'pulsa', 'tagihan', 'biaya', 'iuran',
    'transfer ke', 'kirim ke', 'buat', 'untuk', 'makan', 'minum',
    'parkir', 'tol', 'ojek', 'grab', 'gojek', 'taxi', 'bus', 'kereta',
    'listrik', 'air', 'internet', 'wifi', 'gas', 'pdam',
    'obat', 'dokter', 'klinik', 'apotek', 'rumah sakit',
    'film', 'bioskop', 'game', 'streaming', 'netflix', 'spotify',
    'buku', 'kursus', 'les', 'sekolah', 'kuliah', 'spp',
    'sumbangan', 'donasi', 'zakat', 'infaq', 'sedekah',
    'belanja', 'bayar', 'keluar', 'kurang', 'potong', 'ambil',
    'modal', 'investasi', 'deposit', 'bisnis', 'usaha',
    'makan', 'minum', 'snack', 'jajan',  # ← TAMBAHKAN
]

# ============================================================
# CATEGORY MAPPING
# ============================================================

CATEGORY_MAP = {
    'makanan': ['makan', 'food', 'resto', 'warung', 'cafe', 'kopi', 'snack', 'jajan', 
                'nasi', 'mie', 'ayam', 'sapi', 'ikan', 'sayur', 'buah', 'minum'],
    'transportasi': ['bensin', 'parkir', 'tol', 'ojek', 'grab', 'gojek', 'taxi', 'bus', 
                     'kereta', 'mobil', 'motor', 'angkut', 'transit'],
    'belanja': ['belanja', 'beli', 'shopping', 'toko', 'mart', 'alfamart', 'indomaret',
                'minimarket', 'supermarket', 'hypermarket'],
    'tagihan': ['tagihan', 'listrik', 'air', 'pdam', 'internet', 'wifi', 'pulsa', 
                'paket data', 'telepon', 'gas', 'bpjs', 'kartu kredit'],
    'kesehatan': ['obat', 'dokter', 'rumah sakit', 'klinik', 'apotek', 'vitamin', 
                  'konsultasi', 'laboratorium', 'rontgen'],
    'hiburan': ['film', 'bioskop', 'game', 'streaming', 'netflix', 'spotify', 
                'youtube', 'premium', 'nonton', 'main', 'liburan', 'wisata'],
    'pendidikan': ['buku', 'kursus', 'les', 'sekolah', 'kuliah', 'spp', 'universitas',
                   'pelatihan', 'seminar', 'webinar', 'workshop'],
    'iuran': ['iuran', 'arisan', 'sumbangan', 'donasi', 'zakat', 'infaq', 'sedekah'],
    'gaji': ['gaji', 'salary', 'upah', 'honor', 'remunerasi'],
    'bonus': ['bonus', 'thr', 'insentif', 'tunjangan'],
    'investasi': ['investasi', 'saham', 'reksadana', 'obligasi', 'deposito', 'emerald'],
    'bisnis': ['bisnis', 'usaha', 'penjualan', 'omzet', 'modal', 'supplier'],
}

# ============================================================
# CONVERSATION STATES
# ============================================================

STATE_WAITING_AMOUNT = 'waiting_amount'
STATE_WAITING_CONFIRMATION = 'waiting_confirmation'
STATE_WAITING_DATE = 'waiting_date'
STATE_WAITING_CATEGORY = 'waiting_category'

# ============================================================
# GEMINI MODELS (yang tersedia dari hasil curl)
# ============================================================

GEMINI_MODELS = [
    'models/gemini-3.7-flash',
    'models/gemini-3.6-flash',
    'models/gemini-3.5-flash',
    'models/gemini-2.5-flash',
    'models/gemini-2.5-flash-lite',
    'models/gemini-2.5-pro',
    'models/gemini-flash-latest',
]

# ============================================================
# DEFAULT VALUES
# ============================================================

DEFAULT_CATEGORY = 'Lainnya'
DEFAULT_CURRENCY = 'IDR'
DATE_FORMAT = '%Y-%m-%d'
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
DEFAULT_PAGE_SIZE = 5
MAX_PAGE_SIZE = 20
MAX_MESSAGE_LENGTH = 4096
MAX_DESCRIPTION_LENGTH = 200
MAX_ITEM_DISPLAY = 10