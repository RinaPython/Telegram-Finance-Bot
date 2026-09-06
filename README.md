# 💰 Telegram Finance Bot

<p align="center">
  <strong>Personal Finance Assistant berbasis Telegram</strong>
</p><p align="center">
  Catat • Kelola • Analisis • Pantau keuangan pribadi langsung dari Telegram
</p><p align="center">
  <a href="https://www.python.org/">
    <img src="https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  </a>
  <a href="https://www.docker.com/">
    <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  </a>
  <a href="https://telegram.org/">
    <img src="https://img.shields.io/badge/Telegram-Bot-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram">
  </a>
  <a href="https://www.google.com/sheets/about/">
    <img src="https://img.shields.io/badge/Google-Sheets-34A853?style=for-the-badge&logo=google-sheets&logoColor=white" alt="Google Sheets">
  </a>
  <a href="https://ai.google.dev/">
    <img src="https://img.shields.io/badge/Google-Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemini">
  </a>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

## 📌 Overview

Telegram Finance Bot adalah aplikasi pencatatan dan pengelolaan keuangan pribadi yang berjalan melalui Telegram.

Aplikasi menggabungkan Python, Docker, Google Gemini AI, Telegram Bot API, dan Google Sheets untuk menyediakan sistem pencatatan keuangan yang sederhana namun lengkap.

Dengan bot ini Anda dapat:

- 💰 **Mencatat pemasukan**
- 💸 **Mencatat pengeluaran**
- 🏦 **Mengelola akun**
- 🏷️ **Mengelola kategori**
- 📋 **Melihat riwayat transaksi**
- 📊 **Melihat dashboard keuangan**
- 📈 **Melihat Profit & Loss**
- 📷 **Memproses receipt/struk**
- 🤖 **Menggunakan Gemini AI**
- 📝 **Mencatat Audit Log**
- 🩺 **Memantau kesehatan aplikasi**
- 🖥️ **Mengelola bot melalui VPS Dashboard**

>🎯 Tujuan: membuat pencatatan keuangan pribadi menjadi cepat, terstruktur, dan dapat dilakukan langsung dari Telegram.

---

## 📚 Daftar Isi

- "✨ Fitur" (#-Fitur)
- "🏗️ Arsitektur" (#️-arsitektur)
- "📋 Persyaratan" (#-persyaratan)
- "🚀 Instalasi" (#-instalasi)
  - "1. Siapkan Credential" (#1-siapkan-credential)
  - "2. Buat Telegram Bot" (#2-buat-telegram-bot)
  - "3. Dapatkan Telegram User ID" (#3-dapatkan-telegram-user-id)
  - "4. Buat Gemini API Key" (#4-buat-gemini-api-key)
  - "5. Siapkan Google Sheets" (#5-siapkan-google-sheets)
  - "6. Buat Google Service Account" (#6-buat-google-service-account)
  - "7. Jalankan Installer" (#7-jalankan-installer)
  - "8. Konfigurasi ".env"" (#8-konfigurasi-env)
  - "9. Validasi Konfigurasi" (#9-validasi-konfigurasi)
  - "10. Jalankan Bot" (#10-jalankan-bot)
- "⏳ WAITING MODE" (#-waiting-mode)
- "🖥️ VPS Dashboard" (#️-vps-dashboard)
- "🐳 Docker" (#-docker)
- "🩺 Health Check" (#-health-check)
- "🔄 Update" (#-update)
- "💾 Backup" (#-backup)
- "🗑️ Uninstall" (#️-uninstall)
- "🔐 Security" (#-security)
- "🛠️ Troubleshooting" (#️-troubleshooting)
- "🧪 Testing" (#-testing)
- "📁 Struktur Project" (#-struktur-project)
- "📄 License" (#-license)

---

# ✨ Fitur

| Fitur | Deskripsi |
|-------|-----------|
| 💰 **Pemasukan** | Mencatat transaksi pemasukan |
| 💸 **Pengeluaran** | Mencatat transaksi pengeluaran |
| 🏦 **Akun** | Mengelola sumber dana/akun |
| 🏷️ **Kategori** | Mengelola kategori transaksi |
| 📊 **Dashboard** | Ringkasan kondisi keuangan |
| 📈 **Profit & Loss** | Melihat pemasukan, pengeluaran, dan laba/rugi |
| 📋 **Riwayat** | Melihat transaksi sebelumnya |
| 🤖 **Gemini AI** | Membantu memahami input transaksi |
| 📷 **Receipt** | Pemrosesan struk/receipt |
| 📊 **Google Sheets** | Penyimpanan dan sinkronisasi data |
| 📝 **Audit Log** | Mencatat aktivitas penting |
| 🩺 **Health Check** | Memantau kesehatan bot |
| 🖥️ **VPS Dashboard** | Mengelola bot dari terminal |
| 🔄 **Update** | Update aplikasi dari GitHub |
| 💾 **Backup** | Backup konfigurasi, data, dan credential |
| 🔐 **WAITING MODE** | Mencegah bot berjalan dengan konfigurasi invalid |

## 🏗️ Arsitektur

┌──────────────────────┐
│       TELEGRAM                      │
│        USER          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│    TELEGRAM BOT      │
│       PYTHON         │
└──────────┬───────────┘
           │
     ┌─────┼─────┐
     │     │     │
     ▼     ▼     ▼
┌────────┐ ┌────────────┐ ┌──────────────┐
│ Gemini │ │   Google   │ │ Application  │
│   AI   │ │   Sheets   │ │   Services   │
└────────┘ └────────────┘ └──────────────┘
           │
           ▼
┌──────────────────────┐
│         VPS          │
│   Docker Compose     │
└──────────────────────┘

---

## 📋 Persyaratan

VPS

**Direkomendasikan:**
- Ubuntu 22.04 LTS atau Ubuntu 24.04 LTS
- RAM minimal 1 GB
- Internet aktif
- Akses root atau sudo

Tidak perlu install Docker manual

Installer akan memeriksa Docker dan memasangnya apabila diperlukan.

---

## 🚀 Instalasi

Instalasi dibagi menjadi beberapa tahap:

1. **Telegram Bot**
2. **Telegram User ID**
3. **Gemini API Key**
4. **Google Spreadsheet**
5. **Google Service Account**
6. **Jalankan Installer**
7. **Konfigurasi .env**
8. **Validasi**
9. **Start Bot**

---

1. **Siapkan Credential**

Sebelum memulai, siapkan:

| Credential | Keterangan |
|-------|-----------|
"TELEGRAM_TOKEN" | Token bot Telegram
"AUTHORIZED_USER_ID" | Telegram User ID yang diizinkan
"GEMINI_API_KEY" | API key Google Gemini
"SPREADSHEET_ID" | ID Google Spreadsheet
"GOOGLE_SHEETS_CREDENTIALS" | File JSON Google Service Account

>🔐 *Jangan upload credential ke publik.*

---

2. **Buat Telegram Bot**

Buka Telegram dan cari:

[@BotFather](https://t.me/BotFather)

Kemudian:

1. *Kirim /newbot*
2. *Masukkan nama bot*
3. *Masukkan username bot*
4. *BotFather memberikan Bot Token*

Contoh:

TELEGRAM_TOKEN=123456789:AAxxxxxxxxxxxxxxxxxxxxxxxx

>⚠️ Token di atas hanya contoh.

Simpan token tersebut untuk konfigurasi ".env".

---

3. **Dapatkan Telegram User ID**

Bot menggunakan User ID untuk membatasi siapa yang dapat menggunakan aplikasi.

Langkah:

1. Buka [@userinfobot](https://t.me/userinfobot)
2. Tekan Start
3. Salin angka User ID

Contoh:

AUTHORIZED_USER_ID=123456789

>ℹ️ Gunakan User ID berupa angka, bukan username seperti "@username".

---

4. **Buat Gemini API Key**

Gemini digunakan untuk fitur AI.

Langkah 1 — Buka Google AI Studio

Buka:

[Google AI Studio](https://aistudio.google.com/apikey)

Login menggunakan akun Google.

Langkah 2 — Buat API Key

Pilih:

[API key](https://aistudio.google.com/app/api-keys)

Kemudian pilih:

Create API key

Ikuti instruksi yang diberikan Google.

Langkah 3 — Salin API Key

Contoh format:

AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

*⚠️ Itu hanya contoh format, bukan API key yang dapat digunakan.*

Langkah 4 — Masukkan ke ".env"

GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

>🔐 Penting jika API key bocor, segera revoke/rotate melalui Google AI Studio.

---

5. **Siapkan Google Sheets**

Google Sheets digunakan sebagai penyimpanan data aplikasi.

Sheet yang digunakan:

Transactions<br>
Accounts<br>
Categories<br>
Settings<br>
AuditLog<br>
PnL<br>

Mendapatkan [Spreadsheet](https://docs.google.com/spreadsheets/u/0) ID

Contoh URL:

https://docs.google.com/spreadsheets/d/1ABCxyz123456789/edit

Bagian berikut adalah Spreadsheet ID:

1ABCxyz123456789

Masukkan:

SPREADSHEET_ID=1ABCxyz123456789

>⚠️ Jangan memasukkan Spreadsheet ID pribadi/produksi ke source code publik.

---

6. **Buat Google Service Account**

Aplikasi membutuhkan Google Service Account untuk mengakses Spreadsheet.

Alur:

Google Cloud<br>
Create Project<br>
Enable Google Sheets API<br>
Create Service Account<br>
Create JSON Key<br>
Download JSON<br>
Upload ke VPS<br>

Credential JSON harus disimpan di:

```bash
/opt/Telegram-Finance-Bot/secrets/
```
Contoh:
```
/opt/Telegram-Finance-Bot/secrets/google-service-account.json
```
Berikan akses ke Spreadsheet

Buka Google Spreadsheet:

Share<br>
   ↓<br>
Tambahkan email Service Account<br>
   ↓<br>
Berikan permission yang diperlukan<br>

Contoh email:

finance-bot@my-project.iam.gserviceaccount.com

>⚠️ Jangan upload file JSON Service Account ke publik.

---

7. **Jalankan Installer**

Masuk ke VPS menggunakan SSH.

Kemudian jalankan:

```bash
curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/install.sh | sudo bash
```

Installer akan menangani proses instalasi secara otomatis.

Alur installer

Check System<br>
     │<br>
     ▼<br>
Install Git<br>
     │<br>
     ▼<br>
Install Docker<br>
     │<br>
     ▼<br>
Clone / Update Repository<br>
     │<br>
     ▼<br>
Setup Application<br>
     │<br>
     ▼<br>
Setup Configuration<br>
     │<br>
     ▼<br>
Validate Configuration<br>
     │<br>
     ├───────────────┐<br>
     │<br>               │
     ▼<br>               ▼
   VALID<br>           INVALID
     │<br>               │
     ▼<br>               ▼
 Start Bot<br>       WAITING MODE
     │<br>
     ▼<br>
Health Check<br>

>⚠️ Installer tidak boleh memaksa bot berjalan apabila konfigurasi penting belum valid.

---

8. **Konfigurasi ".env"**

Masuk ke direktori aplikasi:

```bash
cd /opt/Telegram-Finance-Bot
```

Buka ".env":
```
sudo nano .env
```

Gunakan format berikut:

TELEGRAM_TOKEN=123456789:AAxxxxxxxxxxxxxxxxxxxxx
AUTHORIZED_USER_ID=123456789
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

SPREADSHEET_ID=1ABCxyz123456789
GOOGLE_SHEETS_CREDENTIALS=/app/secrets/google-service-account.json

DELETE_MESSAGES=true
HISTORY_PAGE_SIZE=5
TZ=Asia/Jakarta
LOG_LEVEL=INFO

Yang harus Anda ubah

Ganti nilai:

TELEGRAM_TOKEN
AUTHORIZED_USER_ID
GEMINI_API_KEY
SPREADSHEET_ID

dengan milik Anda.

>⚠️ Jangan mengubah nama variabel.

---

9. **Validasi Konfigurasi**

Setelah ".env" selesai:

```bash
sudo ./scripts/validate-config.sh
```

Pastikan konfigurasi penting terdeteksi dengan benar.

Jika terdapat error:

❌ Configuration Invalid

perbaiki ".env" terlebih dahulu.

Jika valid:

✅ Configuration Valid

bot dapat dijalankan.

---

10. **Jalankan Bot**

Setelah konfigurasi valid:

```bash
sudo ./scripts/start-app.sh
```
Kemudian periksa:

```
sudo docker compose ps
```

Jika container berjalan dengan baik, buka bot Anda di Telegram dan tekan:

**/start**

Kemudian lakukan transaksi percobaan.

---

# ⏳ WAITING MODE

WAITING MODE merupakan mekanisme keamanan untuk mencegah bot berjalan menggunakan konfigurasi yang belum lengkap atau invalid.

Jika salah satu konfigurasi penting bermasalah:

❌ Telegram Token<br>
❌ Authorized User ID<br>
❌ Gemini API Key<br>
❌ Spreadsheet ID<br>
❌ Google Sheets Credential<br>

bot tidak akan dijalankan secara normal.

Contoh:

╔══════════════════════════════════════════════╗
║              WAITING MODE                    ║
╠══════════════════════════════════════════════╣
║ Configuration is incomplete/invalid.         ║
║                                              ║
║ Bot will NOT be started.                     ║
║                                              ║
║ Fix configuration and run the dashboard.     ║
╚══════════════════════════════════════════════╝

Setelah konfigurasi diperbaiki:

```bash
cd /opt/Telegram-Finance-Bot
sudo ./scripts/dashboard.sh
```

Kemudian pilih:

**START BOT**

---

## 🖥️ VPS Dashboard

Dashboard digunakan untuk mengelola aplikasi dari terminal.

Jalankan:

```bash
cd /opt/Telegram-Finance-Bot
sudo ./scripts/dashboard.sh
```

Contoh menu:

╔══════════════════════════════════════════════╗
║              FINANCE BOT SERVER              ║
╠══════════════════════════════════════════════╣
║  1. START BOT                                ║
║  2. STOP BOT                                 ║
║  3. RESTART BOT                              ║
║  4. STATUS                                   ║
║  5. VIEW LOG                                 ║
║  6. HEALTH CHECK                             ║
║  7. UPDATE                                   ║
║  8. BACKUP                                   ║
║  9. UNINSTALL                                ║
║  0. EXIT                                     ║
╚══════════════════════════════════════════════╝

>ℹ️ Nama dan jumlah menu mengikuti versi dashboard pada repository.

---

## 🐳 Docker

**Status**

```
sudo docker compose ps
```

**Log**

```
sudo docker compose logs -f finance-bot
```

**100 log terakhir**

```
sudo docker compose logs --tail=100 finance-bot
```

**Restart**

```
sudo docker compose restart
```

**Stop**

```
sudo docker compose stop
```

---

## 🩺 Health Check

**Periksa status:***

```
sudo docker compose ps
```

**Periksa health:**

```
sudo docker inspect \
  --format='{{.State.Health.Status}}' \
  finance-bot
```

**Status yang diharapkan:**

**healthy**

**Jika bermasalah:**

```
sudo docker inspect \
  --format='{{json .State.Health}}' \
  finance-bot
```
**Kemudian:**

```
sudo docker compose logs --tail=200 finance-bot
```

---

## 🔄 Update

**Untuk memperbarui aplikasi:**

```
cd /opt/Telegram-Finance-Bot
sudo ./update.sh
```

**Update menggunakan:**

```
git pull --ff-only
```

**Project tidak menggunakan:**

```
git reset --hard
git stash
```

*sehingga perubahan lokal tidak dihapus secara otomatis.*

*Setelah update, pastikan konfigurasi tetap valid.*

---

## 💾 Backup

**Buat backup:**

```
cd /opt/Telegram-Finance-Bot
sudo ./backup.sh
```

*Data penting yang dapat dibackup:*

**.env**<br>
**data/**<br>
**secrets/**<br>

**Lokasi backup:**

```
/opt/Telegram-Finance-Bot/backups/
```

>🔐 Backup dapat berisi credential sensitif. Jangan upload direktori "backups/" ke publik.

---

## 🗑️ Uninstall

**Jalankan:**

```
cd /opt/Telegram-Finance-Bot
sudo ./uninstall.sh
```

**Tersedia dua pilihan.**

*🟢 Preserve Data*

**Menghapus aplikasi tetapi mempertahankan:**

**.env**<br>
**data/**<br>
**secrets/**<br>
**backups/**<br>

>Cocok untuk instalasi ulang.

*🔴 Remove Everything*

**Menghapus aplikasi beserta data terkait.**

Untuk mengurangi risiko penghapusan tidak sengaja, diperlukan konfirmasi:

*HAPUS SEMUA*

>⚠️ Selalu buat backup sebelum memilih Remove Everything.

---

## 🔐 Security

Credential yang harus dirahasiakan

Jangan pernah commit:

.env<br>
secrets/<br>
*.json<br>
credentials.json<br>
token.json<br>
*.pem<br>
*.key<br>

Credential penting:

TELEGRAM_TOKEN<br>
GEMINI_API_KEY<br>
Google Service Account JSON<br>

Pastikan:

.gitignore<br>
.dockerignore<br>

melindungi file sensitif.

Jika credential bocor

Segera:

1. Revoke credential lama.<br>
2. Buat credential baru.<br>
3. Perbarui ".env".<br>
4. Jalankan validasi.<br>
5. Restart bot.<br>

---

## 🛠️ Troubleshooting

Bot tidak berjalan

**Periksa container:**

```
sudo docker compose ps
```

**Periksa log:**

```
sudo docker compose logs --tail=200 finance-bot
```
---

Configuration Invalid

Jalankan:

```
sudo ./scripts/validate-config.sh
```

Perbaiki error yang ditampilkan.

Kemudian:

```
sudo ./scripts/start-app.sh
```

---

Google Sheets tidak terhubung

Periksa credential:

```
ls -la /opt/Telegram-Finance-Bot/secrets/
```

Periksa konfigurasi:

```
grep -E 'SPREADSHEET_ID|GOOGLE_SHEETS_CREDENTIALS' .env
```
Pastikan:

- Spreadsheet ID benar.<br>
- File JSON tersedia.<br>
- Service Account memiliki akses ke Spreadsheet.<br>
- Google Sheets API telah diaktifkan.<br>

---

Gemini tidak bekerja

Periksa apakah konfigurasi tersedia:

grep GEMINI_API_KEY .env

>⚠️ Jangan membagikan output command tersebut karena dapat berisi API key.

**Kemudian restart:**

```
sudo docker compose restart
```

---

Container Unhealthy

Periksa:

```
sudo docker compose ps
```

Kemudian:

```
sudo docker inspect \
  --format='{{json .State.Health}}' \
  finance-bot
```

Dan:

```
sudo docker compose logs --tail=200 finance-bot
```

---

## 🧪 Testing Checklist

Sebelum menggunakan aplikasi di VPS produksi:

☐ Fresh VPS installation<br>
☐ Telegram credential valid<br>
☐ Telegram credential invalid<br>
☐ Telegram User ID valid<br>
☐ Telegram User ID invalid<br>
☐ Gemini API key valid<br>
☐ Gemini API key invalid<br>
☐ Google Sheets credential valid<br>
☐ Google Sheets credential invalid<br>
☐ Missing .env<br>
☐ Partial configuration<br>
☐ WAITING MODE<br>
☐ Dashboard Start<br>
☐ Dashboard Stop<br>
☐ Dashboard Restart<br>
☐ Health Check<br>
☐ Update<br>
☐ Backup<br>
☐ Preserve-data uninstall<br>
☐ Full uninstall<br>
☐ Docker restart<br>

---

# 📁 Struktur Project

```
Telegram-Finance-Bot/
│
├── install.sh
├── update.sh
├── backup.sh
├── uninstall.sh
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── .env.example
├── .gitignore
├── .dockerignore
├── README.md
│
├── docs/
│
├── scripts/
│   ├── check-system.sh
│   ├── dashboard.sh
│   ├── health-check.sh
│   ├── install-docker.sh
│   ├── setup-app.sh
│   ├── setup-config.sh
│   ├── start-app.sh
│   └── validate-config.sh
│
├── src/
│   ├── main.py
│   ├── bot.py
│   ├── config/
│   ├── handlers/
│   ├── models/
│   ├── services/
│   └── utils/
│
└── tests/
```

Runtime directory

Direktori berikut dibuat/digunakan saat aplikasi berjalan:

data/<br>
logs/<br>
backups/<br>
secrets/<br>
.env<br>

Direktori tersebut tidak boleh dimasukkan ke repository publik.

---

# 📋 Perintah Penting

| Fungsi | Command |
|-------|-----------|
🚀 Install | curl -fsSL https://raw.githubusercontent.com/RinaPython/Telegram-Finance-Bot/main/install.sh | sudo bash
🖥️ Dashboard| sudo ./scripts/dashboard.sh
▶️ Start| sudo ./scripts/start-app.sh
🔄 Update| sudo ./update.sh
💾 Backup| sudo ./backup.sh
🩺 Health| sudo ./scripts/health-check.sh
🗑️ Uninstall| sudo ./uninstall.sh
📋 Status| sudo docker compose ps
📜 Logs| sudo docker compose logs -f finance-bot

---

## 📄 License

This project is licensed under the MIT License.

---

## ❤️ Credits

Dibuat untuk membantu pengelolaan keuangan pribadi dengan cara yang sederhana melalui Telegram.

Built with

<p align="center">
  Python • Docker • Telegram • Gemini AI • Google Sheets
</p><p align="center">
  <strong>💰 Track your money. Understand your finance.</strong>
</p><p align="center">
  Made with ❤️ for personal finance
</p>