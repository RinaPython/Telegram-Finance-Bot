#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - SETUP CONFIG v2.5
# ============================================================
# Wizard konfigurasi dengan input aman dari /dev/tty
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
ENV_FILE="$INSTALL_DIR/.env"
SECRETS_DIR="$INSTALL_DIR/secrets"
CRED_FILE="$SECRETS_DIR/google-service-account.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }

# ============================================================
# FUNGSI INPUT DARI /dev/tty (AMAN UNTUK curl | bash)
# ============================================================

# Membaca input dari terminal, bahkan jika stdin adalah pipe
read_from_tty() {
    local prompt="$1"
    local secret_mode="${2:-false}"
    local input=""
    local max_attempts=3
    local attempt=0

    # Cek apakah /dev/tty tersedia
    if [[ ! -e /dev/tty ]]; then
        print_error "Terminal interaktif tidak tersedia (/dev/tty tidak ditemukan)."
        print_info "Jalankan installer dari terminal interaktif."
        return 1
    fi

    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))

        # Tampilkan prompt ke stderr
        echo -n "$prompt" >&2

        if [[ "$secret_mode" == "true" ]]; then
            # Mode rahasia: matikan echo, baca dari /dev/tty, nyalakan echo
            if stty -echo < /dev/tty 2>/dev/null; then
                # Baca input dari /dev/tty
                IFS= read -r input < /dev/tty
                local stty_exit_code=$?
                stty echo < /dev/tty 2>/dev/null
                echo "" >&2 # Baris baru setelah input
                if [[ $stty_exit_code -ne 0 ]]; then
                    print_error "Gagal membaca input (stty error)."
                    continue
                fi
            else
                print_error "Gagal mengatur mode terminal untuk input rahasia."
                # Fallback: baca tanpa stty
                IFS= read -r input < /dev/tty
                echo "" >&2
            fi
        else
            # Mode normal: baca langsung dari /dev/tty
            IFS= read -r input < /dev/tty
            if [[ $? -ne 0 ]]; then
                print_error "Gagal membaca input dari terminal."
                continue
            fi
        fi

        # Jika input tidak kosong, keluar dari loop
        if [[ -n "$input" ]]; then
            echo "$input"
            return 0
        else
            if [[ $attempt -lt $max_attempts ]]; then
                print_warning "Input tidak boleh kosong. Percobaan $attempt/$max_attempts."
            fi
        fi
    done

    # Jika mencapai sini, semua percobaan gagal
    print_error "Gagal mendapatkan input setelah $max_attempts percobaan."
    return 1
}

# ============================================================
# CEK .ENV YANG SUDAH ADA
# ============================================================

ENV_EXISTS=false
if [[ -f "$ENV_FILE" ]]; then
    ENV_EXISTS=true
    print_success "File .env sudah ada."
    print_info "Mempertahankan konfigurasi yang sudah ada."
    echo ""
    # Load .env yang ada
    set -a
    source "$ENV_FILE"
    set +a
fi

# ============================================================
# BUAT .ENV JIKA BELUM ADA
# ============================================================

if [[ "$ENV_EXISTS" == false ]]; then
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
        cp "$INSTALL_DIR/.env.example" "$ENV_FILE"
        chmod 600 "$ENV_FILE"
        print_success "File .env dibuat."
    else
        print_error "File .env.example tidak ditemukan."
        exit 1
    fi
fi

# ============================================================
# BUAT SECRETS DIRECTORY
# ============================================================

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

# ============================================================
# WIZARD KONFIGURASI (HANYA UNTUK YANG KOSONG)
# ============================================================

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}${BOLD}Konfigurasi Bot${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# --- TELEGRAM BOT TOKEN ---
if [[ -z "${TELEGRAM_TOKEN:-}" ]]; then
    echo -e "${WHITE}Telegram Bot Token${NC}"
    echo "Token diperoleh dari @BotFather di Telegram."
    TELEGRAM_TOKEN=""
    if ! TELEGRAM_TOKEN=$(read_from_tty "Masukkan Telegram Bot Token: " "true"); then
        print_error "Gagal mendapatkan TELEGRAM_TOKEN. Instalasi dihentikan."
        exit 1
    fi
    sed -i "s/^TELEGRAM_TOKEN=.*/TELEGRAM_TOKEN=$TELEGRAM_TOKEN/" "$ENV_FILE"
    print_success "TELEGRAM_TOKEN disimpan."
else
    print_info "TELEGRAM_TOKEN sudah ada (dipertahankan)."
fi
echo ""

# --- AUTHORIZED USER ID ---
if [[ -z "${AUTHORIZED_USER_ID:-}" ]]; then
    echo -e "${WHITE}Telegram User ID${NC}"
    echo "ID pengguna diperoleh dari @userinfobot di Telegram."
    AUTHORIZED_USER_ID=""
    if ! AUTHORIZED_USER_ID=$(read_from_tty "Masukkan Authorized User ID: " "false"); then
        print_error "Gagal mendapatkan AUTHORIZED_USER_ID. Instalasi dihentikan."
        exit 1
    fi
    sed -i "s/^AUTHORIZED_USER_ID=.*/AUTHORIZED_USER_ID=$AUTHORIZED_USER_ID/" "$ENV_FILE"
    print_success "AUTHORIZED_USER_ID disimpan."
else
    print_info "AUTHORIZED_USER_ID sudah ada (dipertahankan)."
fi
echo ""

# --- GEMINI API KEY ---
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    echo -e "${WHITE}Gemini API Key${NC}"
    echo "API Key diperoleh dari Google AI Studio."
    GEMINI_API_KEY=""
    if ! GEMINI_API_KEY=$(read_from_tty "Masukkan Gemini API Key: " "true"); then
        print_error "Gagal mendapatkan GEMINI_API_KEY. Instalasi dihentikan."
        exit 1
    fi
    sed -i "s/^GEMINI_API_KEY=.*/GEMINI_API_KEY=$GEMINI_API_KEY/" "$ENV_FILE"
    print_success "GEMINI_API_KEY disimpan."
else
    print_info "GEMINI_API_KEY sudah ada (dipertahankan)."
fi
echo ""

# --- GOOGLE SHEETS (OPSIONAL) ---
echo -e "${WHITE}Google Sheets (Opsional)${NC}"
echo "Fitur ini menyimpan data ke Google Sheets."

GS_CURRENT_STATUS="OFF"
if [[ -n "${SPREADSHEET_ID:-}" ]] || [[ -f "$CRED_FILE" ]]; then
    GS_CURRENT_STATUS="ON"
fi

if [[ "$GS_CURRENT_STATUS" == "ON" ]]; then
    print_info "Google Sheets terdeteksi dalam konfigurasi."
    echo ""
    if ! read_from_tty "Apakah Anda ingin mengubah konfigurasi Google Sheets? (y/n): " "false" | grep -q "^[Yy]$"; then
        print_info "Konfigurasi Google Sheets dipertahankan."
        echo ""
        print_success "Konfigurasi selesai."
        echo ""
        print_info "File .env: $ENV_FILE"
        exit 0
    fi
fi

if read_from_tty "Apakah Anda ingin menggunakan Google Sheets? (y/n): " "false" | grep -q "^[Yy]$"; then
    echo ""

    # Spreadsheet ID
    SPREADSHEET_ID=""
    if ! SPREADSHEET_ID=$(read_from_tty "Spreadsheet ID (dari URL Google Sheets): " "false"); then
        print_warning "Spreadsheet ID tidak dimasukkan."
        sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=/" "$ENV_FILE"
    else
        sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=$SPREADSHEET_ID/" "$ENV_FILE"
        print_success "SPREADSHEET_ID disimpan."
    fi
    echo ""

    # Google Service Account Credential (JSON)
    echo -e "${WHITE}Google Service Account Credential (JSON)${NC}"
    echo "Masukkan JSON credential dari Google Cloud Console."
    echo "Credential akan disimpan di: $CRED_FILE"
    echo "Akhiri dengan Ctrl+D pada baris kosong:"
    echo ""

    CREDENTIALS_JSON=""
    while IFS= read -r line; do
        CREDENTIALS_JSON+="$line"
    done < /dev/tty

    if [[ -n "$CREDENTIALS_JSON" ]]; then
        if echo "$CREDENTIALS_JSON" | jq -e . >/dev/null 2>&1; then
            echo "$CREDENTIALS_JSON" > "$CRED_FILE"
            chmod 600 "$CRED_FILE"
            print_success "Credential disimpan di: $CRED_FILE"
            CLIENT_EMAIL=$(echo "$CREDENTIALS_JSON" | jq -r '.client_email' 2>/dev/null)
            [[ -n "$CLIENT_EMAIL" && "$CLIENT_EMAIL" != "null" ]] && print_success "Client Email: $CLIENT_EMAIL"

            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=\/app\/secrets\/google-service-account.json/" "$ENV_FILE"
            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
        else
            print_warning "JSON tidak valid. Konfigurasi tetap disimpan untuk perbaikan nanti."
            echo "$CREDENTIALS_JSON" > "$CRED_FILE"
            chmod 600 "$CRED_FILE"
            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=\/app\/secrets\/google-service-account.json/" "$ENV_FILE"
            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
        fi
    else
        print_warning "Credential tidak dimasukkan."
        sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=/" "$ENV_FILE"
        sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
        rm -f "$CRED_FILE" 2>/dev/null || true
    fi
else
    print_info "Google Sheets tidak digunakan."
    sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=/" "$ENV_FILE"
    sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=/" "$ENV_FILE"
    sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
    rm -f "$CRED_FILE" 2>/dev/null || true
fi

# ============================================================
# SELESAI
# ============================================================
echo ""
print_success "Konfigurasi selesai."
echo ""
print_info "File .env: $ENV_FILE"
if [[ -f "$CRED_FILE" ]]; then
    print_info "Credential: $CRED_FILE"
fi
