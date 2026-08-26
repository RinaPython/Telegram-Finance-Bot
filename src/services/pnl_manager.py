"""PNL sheet management service — FORMAT RAPIH & PROFESIONAL"""

import time
from typing import List, Dict, Any, Optional

from src.services.google_sheets import get_google_sheets
from src.services.financial_analytics import FinancialAnalytics
from src.utils.logger import logger
from src.config.settings import settings
from src.utils.timezone import get_timestamp


class PNLManager:
    """Manage PNL sheet updates with optimized professional formatting."""
    
    @staticmethod
    def update_pnl(user_id: Optional[str] = None) -> bool:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            logger.warning("Google Sheets not available")
            return False
        
        try:
            if user_id:
                transactions = gs.get_transactions(user_id)
            else:
                transactions = gs.get_all_transactions()
            
            # ============================================================
            # DEBUG LOG
            # ============================================================
            logger.info(f"📊 Found {len(transactions)} transactions for PNL")
            for t in transactions[:3]:
                logger.info(f"  Transaction: {t.get('Description')} = {t.get('Amount')}")
            
            if transactions:
                from src.services.financial_analytics import FinancialAnalytics
                from src.models.financial_summary import FinancialSummary
                summary = FinancialAnalytics.calculate_summary(transactions)
                monthly = FinancialAnalytics.get_monthly_summary(transactions)
                categories = FinancialAnalytics.get_category_breakdown(transactions)
            else:
                from src.models.financial_summary import FinancialSummary
                summary = FinancialSummary()
                monthly = {}
                categories = []
            
            # ============================================================
            # LOG SUMMARY
            # ============================================================
            logger.info(f"📊 PNL Summary: Income={summary.total_income}, Expense={summary.total_expense}")
            
            # Update data sequentially
            PNLManager._update_title_and_summary(gs.pnl_sheet, summary, user_id)
            time.sleep(0.5)
            
            PNLManager._update_monthly(gs.pnl_sheet, monthly, user_id)
            time.sleep(0.5)
            
            PNLManager._update_categories(gs.pnl_sheet, categories, user_id)
            time.sleep(0.5)
            
            # Apply styling & auto resize
            PNLManager._format_sheet(gs.pnl_sheet)
            
            logger.info(f"✅ PNL updated successfully for user: {user_id or 'global'}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating PNL: {e}", exc_info=True)
            return False

    @staticmethod
    def _update_title_and_summary(pnl_sheet, summary, user_id: Optional[str] = None):
        try:
            timestamp = get_timestamp()
            pnl_sheet.update('A1:G1', [['📊 PROFIT & LOSS STATEMENT']])
            pnl_sheet.update('A2:B2', [['Last Updated:', timestamp]])

            if user_id:
                data = [
                    ['📌 RINGKASAN EKSEKUTIF', '', ''],
                    ['METRIK', 'JUMLAH (IDR)', 'USER ID'],
                    ['Total Income', summary.total_income, user_id],
                    ['Total Expense', summary.total_expense, user_id],
                    ['Net Profit / Loss', summary.net_profit, user_id],
                    ['Savings Rate', summary.savings_rate, user_id],
                    ['Total Transactions', summary.total_transactions, user_id]
                ]
            else:
                data = [
                    ['📌 RINGKASAN EKSEKUTIF', ''],
                    ['METRIK', 'JUMLAH (IDR)'],
                    ['Total Income', summary.total_income],
                    ['Total Expense', summary.total_expense],
                    ['Net Profit / Loss', summary.net_profit],
                    ['Savings Rate', summary.savings_rate],
                    ['Total Transactions', summary.total_transactions]
                ]
            pnl_sheet.update('A3', data, value_input_option='USER_ENTERED')
        except Exception as e:
            logger.error(f"Error update summary: {e}", exc_info=True)

    @staticmethod
    def _update_monthly(pnl_sheet, monthly, user_id: Optional[str] = None):
        try:
            pnl_sheet.update('A10:G10', [['📅 LAPORAN KINERJA BULANAN']])
            
            if not monthly:
                pnl_sheet.batch_clear(['A11:G24'])
                return
            
            sorted_months = sorted(monthly.items())
            
            if user_id:
                headers = ['BULAN', 'INCOME', 'EXPENSE', 'NET P/L', 'SAVINGS %', 'USER ID']
                data = [headers]
                for month_key, month_data in sorted_months:
                    income = month_data.income
                    expense = month_data.expense
                    net = income - expense
                    savings_rate = (net / income * 100) if income > 0 else 0
                    data.append([month_data.month_name, income, expense, net, savings_rate, user_id])
            else:
                headers = ['BULAN', 'INCOME', 'EXPENSE', 'NET P/L', 'SAVINGS %']
                data = [headers]
                for month_key, month_data in sorted_months:
                    income = month_data.income
                    expense = month_data.expense
                    net = income - expense
                    savings_rate = (net / income * 100) if income > 0 else 0
                    data.append([month_data.month_name, income, expense, net, savings_rate])
                    
            pnl_sheet.update('A11', data, value_input_option='USER_ENTERED')
        except Exception as e:
            logger.error(f"Error update monthly: {e}", exc_info=True)

    @staticmethod
    def _update_categories(pnl_sheet, categories, user_id: Optional[str] = None):
        try:
            pnl_sheet.update('A25:G25', [['🏷️ BREAKDOWN KATEGORI PENGELUARAN & PEMASUKAN']])
            
            if not categories:
                pnl_sheet.batch_clear(['A26:G42'])
                return
            
            total = sum(c.amount for c in categories)
            
            if user_id:
                headers = ['KATEGORI', 'JUMLAH (IDR)', 'PORSI (%)', 'USER ID']
                data = [headers]
                for cat in categories[:15]:
                    percentage = (cat.amount / total * 100) if total > 0 else 0
                    data.append([cat.category, cat.amount, percentage, user_id])
            else:
                headers = ['KATEGORI', 'JUMLAH (IDR)', 'PORSI (%)']
                data = [headers]
                for cat in categories[:15]:
                    percentage = (cat.amount / total * 100) if total > 0 else 0
                    data.append([cat.category, cat.amount, percentage])
                    
            pnl_sheet.update('A26', data, value_input_option='USER_ENTERED')
        except Exception as e:
            logger.error(f"Error update categories: {e}", exc_info=True)

    @staticmethod
    def _format_sheet(pnl_sheet):
        try:
            NAVY_HEADER = {'red': 0.11, 'green': 0.21, 'blue': 0.36}
            SLATE_SECTION = {'red': 0.20, 'green': 0.29, 'blue': 0.37}
            SUBHEADER_BG = {'red': 0.90, 'green': 0.93, 'blue': 0.96}
            WHITE_TEXT = {'red': 1.0, 'green': 1.0, 'blue': 1.0}
            DARK_TEXT = {'red': 0.15, 'green': 0.15, 'blue': 0.15}

            pnl_sheet.format('A1:G1', {
                'textFormat': {'bold': True, 'fontSize': 14, 'foregroundColor': WHITE_TEXT},
                'backgroundColor': NAVY_HEADER,
                'horizontalAlignment': 'LEFT',
                'verticalAlignment': 'MIDDLE'
            })

            pnl_sheet.format('A2:B2', {
                'textFormat': {'italic': True, 'fontSize': 9, 'foregroundColor': DARK_TEXT},
                'horizontalAlignment': 'LEFT'
            })

            section_ranges = ['A3:G3', 'A10:G10', 'A25:G25']
            for rng in section_ranges:
                pnl_sheet.format(rng, {
                    'textFormat': {'bold': True, 'fontSize': 11, 'foregroundColor': WHITE_TEXT},
                    'backgroundColor': SLATE_SECTION,
                    'horizontalAlignment': 'LEFT',
                    'verticalAlignment': 'MIDDLE'
                })

            table_headers = ['A4:G4', 'A11:G11', 'A26:G26']
            for rng in table_headers:
                pnl_sheet.format(rng, {
                    'textFormat': {'bold': True, 'fontSize': 10, 'foregroundColor': DARK_TEXT},
                    'backgroundColor': SUBHEADER_BG,
                    'horizontalAlignment': 'CENTER',
                    'verticalAlignment': 'MIDDLE'
                })

            pnl_sheet.format('A5:A9', {'horizontalAlignment': 'LEFT'})
            pnl_sheet.format('B5:B7', {
                'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'},
                'horizontalAlignment': 'RIGHT'
            })
            pnl_sheet.format('B8', {
                'numberFormat': {'type': 'PERCENT', 'pattern': '0.0%'},
                'horizontalAlignment': 'RIGHT'
            })
            pnl_sheet.format('B9', {
                'numberFormat': {'type': 'NUMBER', 'pattern': '#,#0'},
                'horizontalAlignment': 'RIGHT'
            })

            try:
                pnl_sheet.format('A12:A24', {'horizontalAlignment': 'CENTER'})
                pnl_sheet.format('B12:D24', {
                    'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'},
                    'horizontalAlignment': 'RIGHT'
                })
                pnl_sheet.format('E12:E24', {
                    'numberFormat': {'type': 'PERCENT', 'pattern': '0.0%'},
                    'horizontalAlignment': 'RIGHT'
                })
            except Exception:
                pass

            try:
                pnl_sheet.format('A27:A42', {'horizontalAlignment': 'LEFT'})
                pnl_sheet.format('B27:B42', {
                    'numberFormat': {'type': 'CURRENCY', 'pattern': '"Rp"#,##0'},
                    'horizontalAlignment': 'RIGHT'
                })
                pnl_sheet.format('C27:C42', {
                    'numberFormat': {'type': 'PERCENT', 'pattern': '0.0%'},
                    'horizontalAlignment': 'RIGHT'
                })
            except Exception:
                pass

            try:
                pnl_sheet.format('C5:C9', {'horizontalAlignment': 'CENTER'})
                pnl_sheet.format('F12:F24', {'horizontalAlignment': 'CENTER'})
                pnl_sheet.format('D27:D42', {'horizontalAlignment': 'CENTER'})
            except Exception:
                pass

            pnl_sheet.columns_auto_resize(1, 7)
            
            logger.info("✅ PNL sheet professional formatting applied")
            
        except Exception as e:
            if '429' in str(e) or 'quota' in str(e).lower():
                logger.warning("⚠️ Rate limit reached, skipping sheet formatting")
            else:
                logger.warning(f"Could not format PNL sheet: {e}")

    @staticmethod
    def clear_pnl(user_id: Optional[str] = None) -> bool:
        gs = get_google_sheets()
        if not gs or not gs.is_initialized:
            return False
        
        try:
            from src.models.financial_summary import FinancialSummary
            summary = FinancialSummary()
            
            PNLManager._update_title_and_summary(gs.pnl_sheet, summary, user_id)
            time.sleep(0.5)
            PNLManager._update_monthly(gs.pnl_sheet, {}, user_id)
            time.sleep(0.5)
            PNLManager._update_categories(gs.pnl_sheet, [], user_id)
            time.sleep(0.5)
            
            PNLManager._format_sheet(gs.pnl_sheet)
            
            logger.info(f"✅ PNL cleared for user: {user_id or 'global'}")
            return True
            
        except Exception as e:
            logger.error(f"Error clearing PNL: {e}", exc_info=True)
            return False
