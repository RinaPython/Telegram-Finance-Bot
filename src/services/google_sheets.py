"""Google Sheets service — LENGKAP DENGAN FORMAT IDR & FIX READING"""

import json
import os
import re
import base64
import binascii
from datetime import datetime
from typing import List, Dict, Optional, Any

import gspread
from oauth2client.service_account import ServiceAccountCredentials
from gspread.exceptions import APIError, WorksheetNotFound

from src.config.settings import settings
from src.utils.logger import logger
from src.models.transaction import Transaction
from src.utils.timezone import get_timestamp


class GoogleSheetsService:
    """Service for Google Sheets operations."""
    
    def __init__(self):
        self.client = None
        self.spreadsheet = None
        self.sheet = None
        self.pnl_sheet = None
        self.is_initialized = False
        
        self._initialize()
    
    def _initialize(self):
        """Initialize Google Sheets connection."""
        if not settings.is_google_sheets_enabled():
            logger.warning("Google Sheets not configured")
            return
        
        try:
            creds = self._get_credentials()
            if not creds:
                logger.error("Failed to get credentials")
                return
            
            spreadsheet_id = settings.get_spreadsheet_id()
            if not spreadsheet_id:
                logger.error("Invalid SPREADSHEET_ID")
                return
            
            self.client = gspread.authorize(creds)
            self.spreadsheet = self.client.open_by_key(spreadsheet_id)
            
            # ============================================================
            # GET OR CREATE TRANSACTIONS SHEET
            # ============================================================
            try:
                self.sheet = self.spreadsheet.worksheet("Transactions")
                logger.info("✅ Found 'Transactions' sheet")
            except WorksheetNotFound:
                self.sheet = self.spreadsheet.add_worksheet(
                    title="Transactions", 
                    rows=1000, 
                    cols=20
                )
                headers = ["ID", "Date", "Amount", "Category", "Description", "User ID", "Timestamp"]
                self.sheet.append_row(headers)
                logger.info("✅ Created 'Transactions' sheet")
            
            # ============================================================
            # FORMAT AMOUNT DI TRANSACTIONS MENJADI IDR
            # ============================================================
            try:
                self.sheet.format('C:C', {
                    'numberFormat': {
                        'type': 'CURRENCY',
                        'pattern': '"Rp"#,##0'
                    }
                })
                self.sheet.columns_auto_resize(1, 7)
                logger.info("✅ Amount column formatted as IDR")
            except Exception as e:
                logger.warning(f"Could not format Amount column: {e}")
            
            # ============================================================
            # GET OR CREATE PNL SHEET
            # ============================================================
            try:
                self.pnl_sheet = self.spreadsheet.worksheet("PNL")
                logger.info("✅ Found 'PNL' sheet")
            except WorksheetNotFound:
                self.pnl_sheet = self.spreadsheet.add_worksheet(
                    title="PNL", 
                    rows=100, 
                    cols=20
                )
                self._initialize_pnl_sheet()
                logger.info("✅ Created 'PNL' sheet")
            
            self.is_initialized = True
            settings.USE_GOOGLE_SHEETS = True
            logger.info("✅ Google Sheets initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing Google Sheets: {e}", exc_info=True)
            self.is_initialized = False
            settings.USE_GOOGLE_SHEETS = False
    
    def _get_credentials(self):
        """Get Google Sheets credentials."""
        raw = settings.GOOGLE_SHEETS_CREDENTIALS_JSON
        
        if raw:
            try:
                credentials_info = json.loads(raw)
                return ServiceAccountCredentials.from_json_keyfile_dict(
                    credentials_info, 
                    ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
                )
            except json.JSONDecodeError:
                try:
                    decoded = base64.b64decode(raw + "===")
                    credentials_info = json.loads(decoded.decode("utf-8"))
                    return ServiceAccountCredentials.from_json_keyfile_dict(
                        credentials_info,
                        ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
                    )
                except (binascii.Error, UnicodeDecodeError, json.JSONDecodeError) as e:
                    logger.error(f"Error decoding Base64 credentials: {e}")
        
        if settings.GOOGLE_SHEETS_CREDENTIALS and os.path.exists(settings.GOOGLE_SHEETS_CREDENTIALS):
            try:
                return ServiceAccountCredentials.from_json_keyfile_name(
                    settings.GOOGLE_SHEETS_CREDENTIALS,
                    ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
                )
            except Exception as e:
                logger.error(f"Error loading credentials from file: {e}")
        
        common_paths = [
            "/app/service-account-key.json",
            "./service-account-key.json",
            "../service-account-key.json",
            os.path.expanduser("~/service-account-key.json")
        ]
        
        for path in common_paths:
            if os.path.exists(path):
                try:
                    return ServiceAccountCredentials.from_json_keyfile_name(
                        path,
                        ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
                    )
                except Exception as e:
                    logger.error(f"Error loading credentials from {path}: {e}")
        
        logger.error("No Google Sheets credentials found")
        return None
    
    def _initialize_pnl_sheet(self):
        """Initialize PNL sheet with headers and formatting."""
        try:
            # ============================================================
            # JUDUL UTAMA
            # ============================================================
            self.pnl_sheet.update('A1', [['📊 PROFIT & LOSS STATEMENT']])
            self.pnl_sheet.update('A2', [['Updated:', get_timestamp()]])
            
            # ============================================================
            # SUMMARY SECTION
            # ============================================================
            self.pnl_sheet.update('A4', [['📊 METRIC', '💰 AMOUNT']])
            self.pnl_sheet.update('A5', [
                ['Total Income', 0],
                ['Total Expense', 0],
                ['Net Profit/Loss', 0],
                ['Savings Rate', 0],
                ['Total Transactions', 0]
            ])
            
            # ============================================================
            # MONTHLY SUMMARY
            # ============================================================
            self.pnl_sheet.update('A10', [['📅 MONTHLY SUMMARY']])
            self.pnl_sheet.update('A11', [['📅 MONTH', '💰 INCOME', '💸 EXPENSE', '📈 NET P/L', '💎 SAVINGS %']])
            
            # ============================================================
            # CATEGORY BREAKDOWN
            # ============================================================
            self.pnl_sheet.update('A25', [['🏷️ CATEGORY BREAKDOWN']])
            self.pnl_sheet.update('A26', [['🏷️ CATEGORY', '💰 AMOUNT', '📊 PERCENTAGE']])
            
            # ============================================================
            # FORMAT AWAL
            # ============================================================
            # Judul utama
            self.pnl_sheet.format('A1:G1', {
                'textFormat': {'bold': True, 'fontSize': 14},
                'backgroundColor': {'red': 0.1, 'green': 0.3, 'blue': 0.5},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}},
                'horizontalAlignment': 'CENTER'
            })
            
            # Header summary
            self.pnl_sheet.format('A4:G4', {
                'textFormat': {'bold': True},
                'backgroundColor': {'red': 0.2, 'green': 0.5, 'blue': 0.7},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}}
            })
            
            # Judul monthly
            self.pnl_sheet.format('A10:G10', {
                'textFormat': {'bold': True, 'fontSize': 12},
                'backgroundColor': {'red': 0.3, 'green': 0.6, 'blue': 0.4},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}},
                'horizontalAlignment': 'CENTER'
            })
            
            # Judul category
            self.pnl_sheet.format('A25:G25', {
                'textFormat': {'bold': True, 'fontSize': 12},
                'backgroundColor': {'red': 0.6, 'green': 0.3, 'blue': 0.5},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}},
                'horizontalAlignment': 'CENTER'
            })
            
            # Header monthly
            self.pnl_sheet.format('A11:G11', {
                'textFormat': {'bold': True},
                'backgroundColor': {'red': 0.2, 'green': 0.4, 'blue': 0.6},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}}
            })
            
            # Header category
            self.pnl_sheet.format('A26:G26', {
                'textFormat': {'bold': True},
                'backgroundColor': {'red': 0.4, 'green': 0.3, 'blue': 0.5},
                'textFormat': {'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}}
            })
            
            # Format angka
            self.pnl_sheet.format('B5:B9', {'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'}})
            self.pnl_sheet.format('B12:E24', {'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'}})
            self.pnl_sheet.format('E12:E24', {'numberFormat': {'type': 'PERCENT', 'pattern': '0.0"%"'}})
            self.pnl_sheet.format('B27:B42', {'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'}})
            self.pnl_sheet.format('C27:C42', {'numberFormat': {'type': 'PERCENT', 'pattern': '0.0"%"'}})
            
            # Auto resize
            self.pnl_sheet.columns_auto_resize(1, 7)
            
            logger.info("✅ PNL sheet initialized with formatting")
        except Exception as e:
            logger.error(f"Error initializing PNL sheet: {e}", exc_info=True)
    
    # ============================================================
    # TRANSACTION OPERATIONS — FIXED UNTUK MEMBACA FORMAT Rp
    # ============================================================
    
    def _parse_amount(self, amount_str: str) -> float:
        """Parse amount string from Google Sheets (handle Rp format)."""
        if not amount_str or amount_str == '':
            return 0
        
        # Cek negatif
        is_negative = amount_str.strip().startswith('-')
        
        # Hapus "Rp", spasi, titik ribuan, dan koma
        cleaned = amount_str.replace('Rp', '').replace(' ', '').replace('.', '').replace(',', '')
        cleaned = cleaned.replace('-', '')
        
        # Jika masih ada karakter non-digit, coba ekstrak angka
        numbers = re.findall(r'\d+', cleaned)
        if numbers:
            amount = float(''.join(numbers))
            return -amount if is_negative else amount
        
        try:
            amount = float(cleaned) if cleaned else 0
            return -amount if is_negative else amount
        except ValueError:
            return 0
    
    def add_transaction(self, transaction: Transaction) -> bool:
        """Add a transaction to Google Sheets."""
        if not self.is_initialized:
            logger.error("Google Sheets not initialized")
            return False
        
        try:
            existing = self._find_transaction_by_id(transaction.id)
            if existing:
                logger.warning(f"Transaction with ID {transaction.id} already exists")
                return False
            
            row = transaction.to_row()
            self.sheet.append_row(row)
            logger.info(f"✅ Transaction added: {transaction.id} - {transaction.description}")
            return True
        except Exception as e:
            logger.error(f"Error adding transaction: {e}", exc_info=True)
            return False
    
    def _find_transaction_by_id(self, transaction_id: str) -> Optional[Dict]:
        """Find a transaction by ID."""
        try:
            all_values = self.sheet.get_all_values()
            if len(all_values) <= 1:
                return None
            
            header = all_values[0]
            id_index = header.index("ID") if "ID" in header else -1
            
            if id_index == -1:
                return None
            
            for row in all_values[1:]:
                if len(row) > id_index and row[id_index] == transaction_id:
                    return dict(zip(header, row))
            
            return None
        except Exception as e:
            logger.error(f"Error finding transaction by ID: {e}")
            return None
    
    def get_transactions(self, user_id: str, limit: int = None) -> List[Dict]:
        """Get transactions for a specific user — FIXED untuk format Rp."""
        if not self.is_initialized:
            logger.error("Google Sheets not initialized")
            return []
        
        try:
            all_values = self.sheet.get_all_values()
            
            if len(all_values) <= 1:
                return []
            
            header = all_values[0]
            
            # Cari index kolom
            id_idx = header.index("ID") if "ID" in header else -1
            date_idx = header.index("Date") if "Date" in header else -1
            amount_idx = header.index("Amount") if "Amount" in header else -1
            category_idx = header.index("Category") if "Category" in header else -1
            desc_idx = header.index("Description") if "Description" in header else -1
            user_idx = header.index("User ID") if "User ID" in header else -1
            ts_idx = header.index("Timestamp") if "Timestamp" in header else -1
            
            if amount_idx == -1 or user_idx == -1:
                logger.error("Required columns not found")
                return []
            
            user_transactions = []
            
            for row in all_values[1:]:
                if len(row) <= max(amount_idx, user_idx):
                    continue
                
                row_user = row[user_idx].strip() if user_idx < len(row) else ''
                if row_user != str(user_id):
                    continue
                
                # ============================================================
                # PERBAIKAN: Parse Amount dengan _parse_amount
                # ============================================================
                amount_str = row[amount_idx].strip() if amount_idx < len(row) else '0'
                amount = self._parse_amount(amount_str)
                
                transaction = {
                    'ID': row[id_idx] if id_idx != -1 and len(row) > id_idx else '',
                    'Date': row[date_idx] if date_idx != -1 and len(row) > date_idx else '',
                    'Amount': amount,
                    'Category': row[category_idx] if category_idx != -1 and len(row) > category_idx else 'Lainnya',
                    'Description': row[desc_idx] if desc_idx != -1 and len(row) > desc_idx else '',
                    'User ID': row_user,
                    'Timestamp': row[ts_idx] if ts_idx != -1 and len(row) > ts_idx else ''
                }
                
                user_transactions.append(transaction)
            
            # Sort by timestamp descending
            user_transactions.sort(key=lambda x: x.get('Timestamp', ''), reverse=True)
            
            if limit:
                return user_transactions[:limit]
            return user_transactions
            
        except Exception as e:
            logger.error(f"Error getting transactions: {e}", exc_info=True)
            return []
    
    def get_all_transactions(self) -> List[Dict]:
        """Get all transactions — FIXED untuk format Rp."""
        if not self.is_initialized:
            logger.error("Google Sheets not initialized")
            return []
        
        try:
            all_values = self.sheet.get_all_values()
            
            if len(all_values) <= 1:
                return []
            
            header = all_values[0]
            
            id_idx = header.index("ID") if "ID" in header else -1
            date_idx = header.index("Date") if "Date" in header else -1
            amount_idx = header.index("Amount") if "Amount" in header else -1
            category_idx = header.index("Category") if "Category" in header else -1
            desc_idx = header.index("Description") if "Description" in header else -1
            user_idx = header.index("User ID") if "User ID" in header else -1
            ts_idx = header.index("Timestamp") if "Timestamp" in header else -1
            
            if amount_idx == -1:
                logger.error("Amount column not found")
                return []
            
            transactions = []
            
            for row in all_values[1:]:
                if len(row) <= amount_idx:
                    continue
                
                # ============================================================
                # PERBAIKAN: Parse Amount dengan _parse_amount
                # ============================================================
                amount_str = row[amount_idx].strip() if amount_idx < len(row) else '0'
                amount = self._parse_amount(amount_str)
                
                transaction = {
                    'ID': row[id_idx] if id_idx != -1 and len(row) > id_idx else '',
                    'Date': row[date_idx] if date_idx != -1 and len(row) > date_idx else '',
                    'Amount': amount,
                    'Category': row[category_idx] if category_idx != -1 and len(row) > category_idx else 'Lainnya',
                    'Description': row[desc_idx] if desc_idx != -1 and len(row) > desc_idx else '',
                    'User ID': row[user_idx] if user_idx != -1 and len(row) > user_idx else '',
                    'Timestamp': row[ts_idx] if ts_idx != -1 and len(row) > ts_idx else ''
                }
                
                transactions.append(transaction)
            
            transactions.sort(key=lambda x: x.get('Timestamp', ''), reverse=True)
            return transactions
            
        except Exception as e:
            logger.error(f"Error getting all transactions: {e}", exc_info=True)
            return []
    
    def delete_transaction(self, user_id: str, transaction_id: str) -> bool:
        """Delete a transaction by ID."""
        if not self.is_initialized:
            return False
        
        try:
            all_values = self.sheet.get_all_values()
            if len(all_values) <= 1:
                return False
            
            header = all_values[0]
            id_index = header.index("ID") if "ID" in header else -1
            user_index = header.index("User ID") if "User ID" in header else -1
            
            if id_index == -1:
                logger.error("ID column not found")
                return False
            
            for i, row in enumerate(all_values[1:], start=2):
                if len(row) > id_index and row[id_index] == transaction_id:
                    if user_index != -1 and len(row) > user_index:
                        if str(row[user_index]) != str(user_id):
                            logger.warning(f"Transaction {transaction_id} belongs to different user")
                            return False
                    self.sheet.delete_rows(i)
                    logger.info(f"✅ Transaction deleted: {transaction_id}")
                    return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error deleting transaction: {e}", exc_info=True)
            return False
    
    def delete_all_transactions(self, user_id: str) -> int:
        """Delete all transactions for a user."""
        if not self.is_initialized:
            return 0
        
        try:
            all_values = self.sheet.get_all_values()
            if len(all_values) <= 1:
                return 0
            
            header = all_values[0]
            user_index = header.index("User ID") if "User ID" in header else -1
            
            if user_index == -1:
                logger.error("User ID column not found")
                return 0
            
            rows_to_delete = []
            for i, row in enumerate(all_values[1:], start=2):
                if len(row) > user_index and str(row[user_index]) == str(user_id):
                    rows_to_delete.append(i)
            
            for row_index in sorted(rows_to_delete, reverse=True):
                self.sheet.delete_rows(row_index)
            
            logger.info(f"✅ Deleted {len(rows_to_delete)} transactions for user {user_id}")
            return len(rows_to_delete)
            
        except Exception as e:
            logger.error(f"Error deleting all transactions: {e}", exc_info=True)
            return 0
    
    def get_transactions_by_date(self, user_id: str, start_date: str, end_date: str) -> List[Dict]:
        """Get transactions in date range."""
        if not self.is_initialized:
            return []
        
        try:
            all_values = self.sheet.get_all_values()
            
            if len(all_values) <= 1:
                return []
            
            header = all_values[0]
            
            date_idx = header.index("Date") if "Date" in header else -1
            amount_idx = header.index("Amount") if "Amount" in header else -1
            category_idx = header.index("Category") if "Category" in header else -1
            desc_idx = header.index("Description") if "Description" in header else -1
            user_idx = header.index("User ID") if "User ID" in header else -1
            ts_idx = header.index("Timestamp") if "Timestamp" in header else -1
            id_idx = header.index("ID") if "ID" in header else -1
            
            if date_idx == -1 or amount_idx == -1 or user_idx == -1:
                logger.error("Required columns not found")
                return []
            
            result = []
            
            for row in all_values[1:]:
                if len(row) <= max(date_idx, amount_idx, user_idx):
                    continue
                
                row_user = row[user_idx].strip() if user_idx < len(row) else ''
                if row_user != str(user_id):
                    continue
                
                row_date = row[date_idx].strip() if date_idx < len(row) else ''
                if not (start_date <= row_date <= end_date):
                    continue
                
                amount_str = row[amount_idx].strip() if amount_idx < len(row) else '0'
                amount = self._parse_amount(amount_str)
                
                transaction = {
                    'ID': row[id_idx] if id_idx != -1 and len(row) > id_idx else '',
                    'Date': row_date,
                    'Amount': amount,
                    'Category': row[category_idx] if category_idx != -1 and len(row) > category_idx else 'Lainnya',
                    'Description': row[desc_idx] if desc_idx != -1 and len(row) > desc_idx else '',
                    'User ID': row_user,
                    'Timestamp': row[ts_idx] if ts_idx != -1 and len(row) > ts_idx else ''
                }
                
                result.append(transaction)
            
            return result
            
        except Exception as e:
            logger.error(f"Error getting transactions by date: {e}", exc_info=True)
            return []


# ============================================================
# GLOBAL INSTANCE
# ============================================================

_google_sheets = None


def init_google_sheets() -> GoogleSheetsService:
    """Initialize and return Google Sheets service."""
    global _google_sheets
    if _google_sheets is None:
        _google_sheets = GoogleSheetsService()
    return _google_sheets


def get_google_sheets() -> Optional[GoogleSheetsService]:
    """Get Google Sheets service instance."""
    global _google_sheets
    return _google_sheets