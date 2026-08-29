# 💼 Finance Assistant Bot

[![Python Version](https://img.shields.io/badge/python-3.11-blue.svg)](https://python.org)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://docker.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Telegram](https://img.shields.io/badge/telegram-bot-blue.svg)](https://t.me)

Bot Telegram untuk pencatatan keuangan pribadi dengan AI (Google Gemini), Google Sheets, dan VPS Dashboard interaktif.

---

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Demo](#-demo)
- [Prasyarat](#-prasyarat)
- [Instalasi Cepat](#-instalasi-cepat)
- [Konfigurasi](#-konfigurasi)
- [Docker Management](#-docker-management)
- [VPS Dashboard](#-vps-dashboard)
- [Perintah Bot](#-perintah-bot)
- [Update & Maintenance](#-update--maintenance)
- [Backup & Restore](#-backup--restore)
- [Troubleshooting](#-troubleshooting)
- [Struktur Project](#-struktur-project)
- [Lisensi](#-lisensi)

---

## ✨ Fitur

| Fitur | Keterangan |
|-------|------------|
| 💳 **Catat Transaksi** | Natural language processing dengan AI (Gemini) + local parser |
| 📸 **Scan Struk** | Scan struk belanja otomatis dengan Gemini Vision |
| 📊 **Dashboard Keuangan** | Ringkasan pemasukan, pengeluaran, dan laba/rugi |
| 📈 **Profit & Loss** | Analisis keuangan lengkap dengan kategori |
| 💡 **Financial Insight** | Analisis cerdas dari data transaksi Anda |
| 📋 **Riwayat Transaksi** | Pagination history dengan filter |
| 📑 **Google Sheets** | Sinkronisasi otomatis ke Google Sheets |
| 🗑️ **Hapus Otomatis** | Pesan transaksi otomatis terhapus setelah 3 detik |
| 🖥️ **VPS Dashboard** | Panel kontrol terminal untuk manajemen bot |
| 🤖 **AI-Powered** | Google Gemini untuk parsing dan scan struk |

---

## 📸 Demo

### Telegram Bot
```

📊 DASHBOARD KEUANGAN

💰 Pemasukan
Rp 16.400.000

💸 Pengeluaran
Rp 5.200.000

📈 Laba Bersih
Rp 11.200.000

💎 Tingkat Tabungan
68.3%

📝 Total Transaksi
3

📋 Transaksi Terakhir
💰 +Rp 16.400.000 — Saldo
💸 -Rp 5.000.000 — Modal Trading
💸 -Rp 200.000 — Modal kuota

```

### VPS Dashboard
```

╔══════════════════════════════════════════════════════════════╗
║              FINANCE BOT SERVER                              ║
╠══════════════════════════════════════════════════════════════╣
║  Status VPS : 2 hours, 15 minutes                           ║
║  Bot Status : RUNNING                                       ║
║  Uptime     : 1 hour, 30 minutes                            ║
║  Health     : HEALTHY                                       ║
╠══════════════════════════════════════════════════════════════╣
║  1. START BOT                                               ║
║  2. STOP BOT                                                ║
║  3. RESTART BOT                                             ║
║  4. REBUILD & START BOT                                     ║
║  5. BOT STATUS                                              ║
║  6. VIEW LOG                                                ║
║  7. SYSTEM STATUS                                           ║
║  8. REFRESH DASHBOARD                                       ║
║  9. REBOOT VPS                                              ║
║  10. UPDATE FROM GITHUB                                     ║
║  0. EXIT                                                    ║
╚══════════════════════════════════════════════════════════════╝

```

---

## 📋 Prasyarat

| Komponen | Spesifikasi |
|----------|-------------|
| **VPS** | Ubuntu 22.04 LTS (Minimal 1GB RAM, 2GB Recommended) |
| **Docker** | Version 20.10+ |
| **Python** | 3.11+ (jika tidak pakai Docker) |
| **Telegram Bot Token** | Dari @BotFather |
| **Google Gemini API Key** | Dari Google AI Studio |
| **Google Sheets API** | Service Account dengan akses ke spreadsheet |

---

## 🚀 Instalasi Cepat

### Satu Perintah Instalasi

```bash
curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/scripts/bootstrap.sh | sudo bash

2. Install VPS (Otomatis)

```bash
sudo bash scripts/install-vps.sh
```

3. Konfigurasi .env

```bash
nano .env
# Isi dengan kredensial Anda
```

4. Jalankan Bot

```bash
docker compose up -d
```

5. Buka Dashboard

```bash
finance-dashboard
```

---

🔧 Konfigurasi

File .env

Buat file .env dari .env.example:

```bash
cp .env.example .env
nano .env
```

Isi dengan nilai yang benar:

```env
# ============================================================
# TELEGRAM BOT CONFIGURATION
# ============================================================
# Get from @BotFather on Telegram
TELEGRAM_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz

# ============================================================
# GEMINI AI CONFIGURATION
# ============================================================
# Get from Google AI Studio: https://aistudio.google.com/apikey
GEMINI_API_KEY=AIzaSyABCdefGHIjklMNOpqrsTUVwxyz

# ============================================================
# AUTHORIZATION
# ============================================================
# Your Telegram User ID (get from @userinfobot)
AUTHORIZED_USER_ID=123456789

# ============================================================
# GOOGLE SHEETS CONFIGURATION
# ============================================================
# Spreadsheet ID from URL
SPREADSHEET_ID=1ABCdefGHIjklMNOpqrsTUVwxyz

# Google Service Account Credentials (JSON format, ONE LINE)
GOOGLE_SHEETS_CREDENTIALS_JSON={"type":"service_account",...}

# ============================================================
# BOT SETTINGS
# ============================================================
DELETE_MESSAGES=true
HISTORY_PAGE_SIZE=5
TZ=Asia/Jakarta
LOG_LEVEL=INFO
```

---

🐳 Docker Management

```bash
# Start bot
docker compose up -d

# Stop bot
docker compose down

# Restart bot
docker compose restart

# View logs
docker compose logs -f

# View last 50 logs
docker compose logs --tail=50

# Rebuild and start
docker compose build --no-cache
docker compose up -d

# Check status
docker compose ps

# Check health
docker inspect finance-bot --format='{{.State.Health.Status}}'
```

---

🖥️ VPS Dashboard

Instal Dashboard

```bash
# Otomatis terinstall saat install-vps.sh
# Atau manual:
sudo bash scripts/install-dashboard.sh
```

Jalankan Dashboard

```bash
finance-dashboard
```

Menu Dashboard

Menu Fungsi
1 START BOT
2 STOP BOT
3 RESTART BOT
4 REBUILD & START BOT
5 BOT STATUS
6 VIEW LOG
7 SYSTEM STATUS
8 REFRESH DASHBOARD
9 REBOOT VPS
10 UPDATE FROM GITHUB
0 EXIT

---

📱 Perintah Bot

Command Deskripsi
/start Menu utama
/menu Tampilkan menu
/dashboard Dashboard keuangan
/pnl Profit & Loss
/riwayat Riwayat transaksi
/catat Catat transaksi
/laporan Laporan keuangan
/sheet Google Sheets
/hapus Hapus data
/pengaturan Pengaturan
/help Panduan
/hapuspesan Toggle auto-delete

---

🔄 Update & Maintenance

Update dari GitHub

```bash
# Via Dashboard: pilih menu 10
# Atau manual:
git pull
docker compose down
docker compose build --no-cache
docker compose up -d
```

Melihat Log

```bash
# Real-time
docker compose logs -f

# 50 baris terakhir
docker compose logs --tail=50

# Log dengan timestamp
docker compose logs --timestamps
```

Restart Setelah VPS Reboot

Bot otomatis restart menggunakan restart: unless-stopped di docker-compose.yml.

---

📦 Backup & Restore

Backup

```bash
cd ~/Telegram-Finance-Bot
tar -czf ../backup-$(date +%Y-%m-%d).tar.gz \
    --exclude=".env" \
    --exclude="*.json" \
    --exclude="data" \
    --exclude="logs" \
    .
```

Restore

```bash
tar -xzf backup-*.tar.gz
docker compose up -d
```

Backup .env (Khusus)

```bash
cp .env .env.backup
```

---

🔧 Troubleshooting

Bot Tidak Jalan

```bash
# Cek log
docker compose logs --tail=50

# Cek status
docker compose ps

# Restart
docker compose restart
```

Container Unhealthy

```bash
# Cek health status
docker inspect finance-bot --format='{{.State.Health.Status}}'

# Cek detail health
docker inspect finance-bot --format='{{json .State.Health}}' | python3 -m json.tool
```

Google Sheets Error

```bash
# Cek .env
cat .env | grep -E "SPREADSHEET_ID|GOOGLE_SHEETS_CREDENTIALS"

# Cek koneksi
docker exec finance-bot python -c "
from src.services.google_sheets import get_google_sheets
gs = get_google_sheets()
print('Connected:', gs.is_initialized)
"
```

Network Error (Bad Gateway)

```bash
# Cek koneksi internet VPS
ping -c 3 8.8.8.8

# Cek Telegram API
curl -I https://api.telegram.org

# Restart Docker
sudo systemctl restart docker
docker compose up -d
```

Permission Denied

```bash
# Fix permission
sudo chown -R $USER:$USER ~/Telegram-Finance-Bot
chmod 755 data logs
chmod 600 .env
```

---

📁 Struktur Project

```
Telegram-Finance-Bot/
├── src/                          # Source code
│   ├── config/                   # Konfigurasi
│   ├── handlers/                 # Command & message handlers
│   ├── services/                 # Business logic
│   ├── models/                   # Data models
│   └── utils/                    # Utility functions
├── scripts/                      # Management scripts
│   ├── install-vps.sh           # Auto installer
│   ├── install-dashboard.sh     # Dashboard installer
│   ├── update.sh                # Update script
│   ├── health-check.sh          # Health check
│   └── start-bot.sh             # Start bot
├── dashboard/                    # VPS Dashboard
│   └── finance-dashboard.sh
├── data/                         # Persistent data
├── logs/                         # Log files
├── docs/                         # Dokumentasi
├── tests/                        # Unit tests
├── .env.example                  # Template environment
├── .gitignore                    # Git ignore
├── Dockerfile                    # Docker build
├── docker-compose.yml            # Docker Compose
├── requirements.txt              # Python dependencies
└── README.md                     # Dokumentasi
```

---

📝 Lisensi

MIT License

---

🙏 Kontribusi

1. Fork repository
2. Buat branch fitur (git checkout -b feature/AmazingFeature)
3. Commit perubahan (git commit -m 'Add some AmazingFeature')
4. Push ke branch (git push origin feature/AmazingFeature)
5. Buka Pull Request

---

📞 Support

· Report Bug
· Request Feature

---

Made with ❤️ for personal finance management 🚀

```

---

## 🔧 CARA MEMBUAT FILE

```bash
cd ~/Telegram-Finance-Bot
nano README.md
# Copy paste isi di atas
# Ctrl+O, Enter, Ctrl+X
```
