#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - SETUP CONFIG v2.4
# ============================================================
# Wizard konfigurasi - aman, tanpa tampilkan private key
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

read_secret() {
    local prompt="$1"
    local secret=""
    local char
    local IFS=
    
    echo -n "$prompt" >&2
    
    stty -echo
    while IFS= read -r -n1 -s char; do
        if [[ $char == $'\0' ]]; then
            break
        elif [[ $char == $'\177' ]]; then
            if [[ -n "$secret" ]]; then
                secret="${secret%?}"
                echo -ne "\b \b" >&2
            fi
        else
            secret+="$char"
            echo -ne "*" >&2
        fi
    done
    stty echo
    echo "" >&2
    echo "$secret"
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
# WIZARD KONFIGURASI
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
    TELEGRAM_TOKEN=$(read_secret "Masukkan Telegram Bot Token: ")
    while [[ -z "$TELEGRAM_TOKEN" ]]; do
        print_error "Token tidak boleh kosong."
        TELEGRAM_TOKEN=$(read_secret "Masukkan Telegram Bot Token: ")
    done
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
    read -p "Masukkan Authorized User ID: " AUTHORIZED_USER_ID
    while [[ -z "$AUTHORIZED_USER_ID" ]]; do
        print_error "User ID tidak boleh kosong."
        read -p "Masukkan Authorized User ID: " AUTHORIZED_USER_ID
    done
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
    GEMINI_API_KEY=$(read_secret "Masukkan Gemini API Key: ")
    while [[ -z "$GEMINI_API_KEY" ]]; do
        print_error "API Key tidak boleh kosong."
        GEMINI_API_KEY=$(read_secret "Masukkan Gemini API Key: ")
    done
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
    read -p "Apakah Anda ingin mengubah konfigurasi Google Sheets? (y/n): " change_gs
    if [[ ! "$change_gs" =~ ^[Yy]$ ]]; then
        print_info "Konfigurasi Google Sheets dipertahankan."
        echo ""
        print_success "Konfigurasi selesai."
        echo ""
        print_info "File .env: $ENV_FILE"
        exit 0
    fi
fi

read -p "Apakah Anda ingin menggunakan Google Sheets? (y/n): " use_gs

if [[ "$use_gs" =~ ^[Yy]$ ]]; then
    echo ""
    
    # Spreadsheet ID
    read -p "Spreadsheet ID (dari URL Google Sheets): " SPREADSHEET_ID
    if [[ -n "$SPREADSHEET_ID" ]]; then
        sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=$SPREADSHEET_ID/" "$ENV_FILE"
        print_success "SPREADSHEET_ID disimpan."
    else
        print_warning "Spreadsheet ID tidak dimasukkan."
        sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=/" "$ENV_FILE"
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
    done
    
    if [[ -n "$CREDENTIALS_JSON" ]]; then
        # Validasi JSON
        if echo "$CREDENTIALS_JSON" | jq -e . >/dev/null 2>&1; then
            # Cek client_email
            CLIENT_EMAIL=$(echo "$CREDENTIALS_JSON" | jq -r '.client_email' 2>/dev/null)
            if [[ -n "$CLIENT_EMAIL" && "$CLIENT_EMAIL" != "null" ]]; then
                # Simpan ke file
                echo "$CREDENTIALS_JSON" > "$CRED_FILE"
                chmod 600 "$CRED_FILE"
                print_success "Credential disimpan di: $CRED_FILE"
                print_success "Client Email: $CLIENT_EMAIL"
                
                # Set GOOGLE_SHEETS_CREDENTIALS di .env
                sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=\/app\/secrets\/google-service-account.json/" "$ENV_FILE"
                sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
            else
                print_warning "JSON tidak memiliki client_email."
                print_info "Konfigurasi tetap disimpan, tetapi validasi akan gagal."
                echo "$CREDENTIALS_JSON" > "$CRED_FILE"
                chmod 600 "$CRED_FILE"
                sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=\/app\/secrets\/google-service-account.json/" "$ENV_FILE"
                sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
            fi
        else
            print_warning "JSON tidak valid. Konfigurasi tetap disimpan untuk perbaikan nanti."
            echo "$CREDENTIALS_JSON" > "$CRED_FILE"
            chmod 600 "$CRED_FILE"
            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=\/app\/secrets\/google-service-account.json/" "$ENV_FILE"
            sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
        fi
    else
        print_warning "Credential tidak dimasukkan. Konfigurasi PARSIAL."
        sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=/" "$ENV_FILE"
        sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
        # Hapus file credential jika ada
        if [[ -f "$CRED_FILE" ]]; then
            rm -f "$CRED_FILE"
            print_info "Credential file yang lama dihapus."
        fi
    fi
else
    print_info "Google Sheets tidak digunakan."
    sed -i "s/^SPREADSHEET_ID=.*/SPREADSHEET_ID=/" "$ENV_FILE"
    sed -i "s/^GOOGLE_SHEETS_CREDENTIALS=.*/GOOGLE_SHEETS_CREDENTIALS=/" "$ENV_FILE"
    sed -i "s/^GOOGLE_SHEETS_CREDENTIALS_JSON=.*/GOOGLE_SHEETS_CREDENTIALS_JSON=/" "$ENV_FILE"
    # Hapus file credential jika ada
    if [[ -f "$CRED_FILE" ]]; then
        rm -f "$CRED_FILE"
        print_info "Credential file yang lama dihapus."
    fi
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