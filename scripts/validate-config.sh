#!/bin/bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM FINANCE BOT - VALIDATE CONFIG v2.5
# ============================================================
# Validasi format & koneksi API - exit code sebagai sumber kebenaran
# ============================================================

INSTALL_DIR="/opt/Telegram-Finance-Bot"
ENV_FILE="$INSTALL_DIR/.env"
SECRETS_DIR="$INSTALL_DIR/secrets"
CRED_FILE="$SECRETS_DIR/google-service-account.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_error() { echo -e "${RED}[✗] ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }
print_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
print_pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; }
print_fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }
print_warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }

SILENT_MODE=false
[[ "${1:-}" == "silent" ]] && SILENT_MODE=true

# ============================================================
# LOAD CONFIG
# ============================================================

if [[ ! -f "$ENV_FILE" ]]; then
    [[ "$SILENT_MODE" == false ]] && print_error "File .env tidak ditemukan: $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

ERROR=0
WARN=0

# ============================================================
# 1. VALIDASI TELEGRAM TOKEN
# ============================================================
print_info "Memeriksa TELEGRAM_TOKEN..."

if [[ -z "${TELEGRAM_TOKEN:-}" ]]; then
    print_fail "TELEGRAM_TOKEN tidak diisi."
    ERROR=1
elif [[ ! "${TELEGRAM_TOKEN}" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
    print_fail "Format TELEGRAM_TOKEN tidak valid."
    ERROR=1
else
    print_pass "Format TELEGRAM_TOKEN valid"
    
    print_info "  Memeriksa koneksi Telegram API..."
    TELEGRAM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getMe" 2>/dev/null)
    
    if [[ "$TELEGRAM_RESPONSE" -eq 200 ]]; then
        BOT_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getMe" 2>/dev/null)
        BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.username' 2>/dev/null || echo "unknown")
        print_pass "Telegram API: BOT VALID (@$BOT_NAME)"
    else
        print_fail "Telegram API: TOKEN TIDAK VALID (HTTP $TELEGRAM_RESPONSE)"
        ERROR=1
    fi
fi

echo ""

# ============================================================
# 2. VALIDASI AUTHORIZED USER ID
# ============================================================
print_info "Memeriksa AUTHORIZED_USER_ID..."

if [[ -z "${AUTHORIZED_USER_ID:-}" ]]; then
    print_fail "AUTHORIZED_USER_ID tidak diisi."
    ERROR=1
elif [[ ! "${AUTHORIZED_USER_ID}" =~ ^[0-9]+$ ]]; then
    print_fail "AUTHORIZED_USER_ID harus berupa angka."
    ERROR=1
else
    print_pass "AUTHORIZED_USER_ID valid (format angka)"
fi

echo ""

# ============================================================
# 3. VALIDASI GEMINI API KEY
# ============================================================
print_info "Memeriksa GEMINI_API_KEY..."

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    print_fail "GEMINI_API_KEY tidak diisi."
    ERROR=1
elif [[ ! "${GEMINI_API_KEY}" =~ ^AIzaSy[A-Za-z0-9_-]+$ ]]; then
    print_warn "Format GEMINI_API_KEY tidak standar (harus dimulai dengan AIzaSy)."
    WARN=1
else
    print_pass "Format GEMINI_API_KEY valid"
fi

if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    print_info "  Memeriksa koneksi Gemini API..."
    GEMINI_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}" 2>/dev/null)
    
    if [[ "$GEMINI_RESPONSE" -eq 200 ]]; then
        print_pass "Gemini API: KEY VALID"
    else
        print_fail "Gemini API: KEY TIDAK VALID (HTTP $GEMINI_RESPONSE)"
        ERROR=1
    fi
fi

echo ""

# ============================================================
# 4. VALIDASI GOOGLE SHEETS
# ============================================================
print_info "Memeriksa Google Sheets..."

# Cek status konfigurasi
GS_SPREADSHEET_ID="${SPREADSHEET_ID:-}"
CRED_FILE_EXISTS=false
[[ -f "$CRED_FILE" ]] && CRED_FILE_EXISTS=true

GS_OFF=false
GS_COMPLETE=false
GS_PARTIAL=false

if [[ -z "$GS_SPREADSHEET_ID" ]] && [[ "$CRED_FILE_EXISTS" == false ]]; then
    GS_OFF=true
    print_warn "Google Sheets tidak dikonfigurasi (opsional) - BOT TETAP BERJALAN"
    echo ""
elif [[ -n "$GS_SPREADSHEET_ID" ]] && [[ "$CRED_FILE_EXISTS" == true ]]; then
    GS_COMPLETE=true
    print_info "  Google Sheets terdeteksi dalam konfigurasi lengkap."
else
    GS_PARTIAL=true
    print_error "  Google Sheets: KONFIGURASI PARSIAL (tidak lengkap)"
    if [[ -z "$GS_SPREADSHEET_ID" ]]; then
        print_fail "  SPREADSHEET_ID tidak diisi"
    else
        print_pass "  SPREADSHEET_ID: ada"
    fi
    if [[ "$CRED_FILE_EXISTS" == false ]]; then
        print_fail "  Credential file tidak ditemukan: $CRED_FILE"
    else
        print_pass "  Credential file: ada"
    fi
    ERROR=1
fi

if [[ "$GS_COMPLETE" == true ]]; then
    GS_VALID=true
    
    # Validasi Spreadsheet ID
    if [[ -n "$GS_SPREADSHEET_ID" ]]; then
        if [[ "${GS_SPREADSHEET_ID}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_pass "  Spreadsheet ID: format valid"
        else
            print_fail "  Spreadsheet ID: format tidak valid"
            GS_VALID=false
            ERROR=1
        fi
    fi
    
    # Validasi Credential file
    if [[ -f "$CRED_FILE" ]]; then
        print_pass "  Credential file: ada"
        if jq -e . "$CRED_FILE" >/dev/null 2>&1; then
            print_pass "  Credential: JSON valid"
            CLIENT_EMAIL=$(jq -r '.client_email' "$CRED_FILE" 2>/dev/null)
            if [[ -n "$CLIENT_EMAIL" && "$CLIENT_EMAIL" != "null" ]]; then
                print_pass "  Client Email: $CLIENT_EMAIL"
            else
                print_fail "  Credential: tidak memiliki client_email"
                GS_VALID=false
                ERROR=1
            fi
        else
            print_fail "  Credential: JSON tidak valid"
            GS_VALID=false
            ERROR=1
        fi
    else
        print_fail "  Credential file tidak ditemukan: $CRED_FILE"
        GS_VALID=false
        ERROR=1
    fi
    
    # ============================================================
    # REAL API VALIDATION - EXIT CODE SEBAGAI SUMBER KEBENARAN
    # ============================================================
    if [[ "$GS_VALID" == true ]]; then
        print_info "  Melakukan validasi REAL API Google Sheets..."
        
        VALIDATION_OUTPUT=""
        VALIDATION_EXIT=1
        
        # Coba di container terlebih dahulu
        if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "finance-bot"; then
            print_info "  Menggunakan environment container untuk validasi..."
            VALIDATION_OUTPUT=$(docker exec finance-bot python3 -c "
import json
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

CRED_FILE = '/app/secrets/google-service-account.json'
SPREADSHEET_ID = '${GS_SPREADSHEET_ID}'

try:
    with open(CRED_FILE, 'r') as f:
        cred_data = json.load(f)
    
    if 'client_email' not in cred_data:
        print('ERROR: Missing client_email')
        sys.exit(1)
    
    client_email = cred_data['client_email']
    print(f'PASS: Client email: {client_email}')
    
    try:
        credentials = service_account.Credentials.from_service_account_file(
            CRED_FILE,
            scopes=['https://www.googleapis.com/auth/spreadsheets.readonly']
        )
        
        service = build('sheets', 'v4', credentials=credentials)
        sheet = service.spreadsheets()
        result = sheet.get(spreadsheetId=SPREADSHEET_ID).execute()
        
        title = result.get('properties', {}).get('title', 'Unknown')
        print(f'PASS: Spreadsheet accessible: {title}')
        sys.exit(0)
        
    except HttpError as e:
        if e.resp.status == 403:
            print('ERROR: Spreadsheet not shared with service account')
            print('ERROR_DETAIL: Add service account email as editor')
            sys.exit(1)
        elif e.resp.status == 404:
            print('ERROR: Spreadsheet not found (invalid ID)')
            print('ERROR_DETAIL: Check spreadsheet ID')
            sys.exit(1)
        else:
            print(f'ERROR: HTTP {e.resp.status}')
            print(f'ERROR_DETAIL: {str(e)}')
            sys.exit(1)
    except Exception as e:
        print(f'ERROR: {str(e)}')
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {str(e)}')
    sys.exit(1)
" 2>&1) || VALIDATION_EXIT=$?
        else
            # Fallback ke host
            print_info "  Container tidak berjalan, mencoba validasi di host..."
            VALIDATION_OUTPUT=$(python3 -c "
import json
import sys
try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print('ERROR: Google API library not available on host')
    print('ERROR_DETAIL: Install google-api-python-client')
    sys.exit(1)

CRED_FILE = '${CRED_FILE}'
SPREADSHEET_ID = '${GS_SPREADSHEET_ID}'

try:
    with open(CRED_FILE, 'r') as f:
        cred_data = json.load(f)
    
    if 'client_email' not in cred_data:
        print('ERROR: Missing client_email')
        sys.exit(1)
    
    client_email = cred_data['client_email']
    print(f'PASS: Client email: {client_email}')
    
    try:
        credentials = service_account.Credentials.from_service_account_file(
            CRED_FILE,
            scopes=['https://www.googleapis.com/auth/spreadsheets.readonly']
        )
        
        service = build('sheets', 'v4', credentials=credentials)
        sheet = service.spreadsheets()
        result = sheet.get(spreadsheetId=SPREADSHEET_ID).execute()
        
        title = result.get('properties', {}).get('title', 'Unknown')
        print(f'PASS: Spreadsheet accessible: {title}')
        sys.exit(0)
        
    except HttpError as e:
        if e.resp.status == 403:
            print('ERROR: Spreadsheet not shared with service account')
            print('ERROR_DETAIL: Add service account email as editor')
            sys.exit(1)
        elif e.resp.status == 404:
            print('ERROR: Spreadsheet not found (invalid ID)')
            print('ERROR_DETAIL: Check spreadsheet ID')
            sys.exit(1)
        else:
            print(f'ERROR: HTTP {e.resp.status}')
            print(f'ERROR_DETAIL: {str(e)}')
            sys.exit(1)
    except Exception as e:
        print(f'ERROR: {str(e)}')
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {str(e)}')
    sys.exit(1)
" 2>&1) || VALIDATION_EXIT=$?
        fi
        
        # ============================================================
        # EXIT CODE SEBAGAI SUMBER KEBENARAN UTAMA
        # ============================================================
        # Tampilkan output untuk informasi
        if [[ -n "$VALIDATION_OUTPUT" ]]; then
            echo "$VALIDATION_OUTPUT" | while IFS= read -r line; do
                if echo "$line" | grep -q "^PASS:"; then
                    print_pass "  $(echo "$line" | sed 's/^PASS: //')"
                elif echo "$line" | grep -q "^ERROR:"; then
                    ERROR_MSG=$(echo "$line" | sed 's/^ERROR: //')
                    if echo "$ERROR_MSG" | grep -q "Spreadsheet not shared"; then
                        print_fail "  Google Sheets: SPREADSHEET BELUM DIBAGIKAN KE SERVICE ACCOUNT"
                        print_info "  Tambahkan email service account ke spreadsheet sebagai editor"
                    elif echo "$ERROR_MSG" | grep -q "Spreadsheet not found"; then
                        print_fail "  Google Sheets: SPREADSHEET ID TIDAK DITEMUKAN"
                        print_info "  Periksa kembali Spreadsheet ID"
                    elif echo "$ERROR_MSG" | grep -q "library not available"; then
                        print_fail "  Google Sheets: LIBRARY TIDAK TERSEDIA"
                    else
                        print_fail "  Google Sheets: $ERROR_MSG"
                    fi
                fi
            done
        fi
        
        # ============================================================
        # KEPUTUSAN BERDASARKAN EXIT CODE
        # ============================================================
        if [[ $VALIDATION_EXIT -eq 0 ]]; then
            print_pass "  Google Sheets: REAL API VALIDATION SUCCESS (exit code 0)"
            print_pass "Google Sheets: KONFIGURASI VALID"
        else
            print_fail "  Google Sheets: REAL API VALIDATION FAILED (exit code $VALIDATION_EXIT)"
            print_fail "Google Sheets: KONFIGURASI TIDAK VALID"
            print_info "  Bot TIDAK akan dijalankan sampai Google Sheets diperbaiki"
            print_info "  atau nonaktifkan Google Sheets dengan memilih 'n' saat instalasi"
            GS_VALID=false
            ERROR=1
        fi
    fi
fi

echo ""

# ============================================================
# HASIL VALIDASI
# ============================================================

if [[ $ERROR -eq 0 ]]; then
    print_success "✅ SEMUA VALIDASI BERHASIL"
    if [[ $WARN -gt 0 ]]; then
        print_warning "⚠️  Ada $WARN peringatan (tidak kritis)"
    fi
    exit 0
else
    print_error "❌ VALIDASI GAGAL ($ERROR error)"
    echo ""
    print_info "Perbaiki konfigurasi di: $ENV_FILE"
    print_info "Kemudian jalankan installer ulang atau start bot dari dashboard."
    exit 1
fi