"""Financial analytics service — FIXED untuk membaca amount"""

import re
from typing import List, Dict, Any
from collections import defaultdict
from datetime import datetime, timedelta

from src.models.financial_summary import (
    FinancialSummary,
    MonthlySummary,
    CategoryBreakdown,
    FinancialInsight,
)
from src.utils.formatters import get_category_emoji
from src.utils.logger import logger
from src.utils.timezone import now, today, get_current_month, JAKARTA_TZ


class FinancialAnalytics:
    """Service for financial calculations and insights."""
    
    @staticmethod
    def _parse_amount(amount_raw: Any) -> float:
        """Parse amount dari berbagai format."""
        if amount_raw is None:
            return 0
        
        # Jika sudah float atau int
        if isinstance(amount_raw, (int, float)):
            return float(amount_raw)
        
        # Jika string
        if isinstance(amount_raw, str):
            # Hapus Rp, spasi, titik, koma
            cleaned = amount_raw.replace('Rp', '').replace(' ', '').replace('.', '').replace(',', '')
            # Hapus tanda minus untuk parsing
            is_negative = cleaned.startswith('-')
            cleaned = cleaned.replace('-', '')
            try:
                amount = float(cleaned) if cleaned else 0
                return -amount if is_negative else amount
            except ValueError:
                return 0
        
        return 0
    
    @staticmethod
    def calculate_summary(transactions: List[Dict]) -> FinancialSummary:
        """Calculate financial summary from transactions."""
        total_income = 0
        total_expense = 0
        income_count = 0
        expense_count = 0
        
        for t in transactions:
            try:
                amount = FinancialAnalytics._parse_amount(t.get('Amount', 0))
                
                if amount > 0:
                    total_income += amount
                    income_count += 1
                elif amount < 0:
                    total_expense += abs(amount)
                    expense_count += 1
            except Exception as e:
                logger.warning(f"Failed to process transaction: {e}")
                continue
        
        net_profit = total_income - total_expense
        savings_rate = (net_profit / total_income * 100) if total_income > 0 else 0
        
        return FinancialSummary(
            total_income=total_income,
            total_expense=total_expense,
            net_profit=net_profit,
            savings_rate=savings_rate,
            total_transactions=len(transactions),
            income_count=income_count,
            expense_count=expense_count
        )
    
    @staticmethod
    def get_monthly_summary(transactions: List[Dict]) -> Dict[str, MonthlySummary]:
        """Get monthly summary from transactions."""
        monthly = {}
        
        for t in transactions:
            try:
                date_str = t.get('Date', '')
                if not date_str:
                    continue
                
                date_obj = datetime.strptime(date_str, '%Y-%m-%d')
                month_key = date_obj.strftime('%Y-%m')
                month_name = date_obj.strftime('%B')
                
                if month_key not in monthly:
                    monthly[month_key] = MonthlySummary(
                        month=month_key,
                        month_name=month_name
                    )
                
                amount = FinancialAnalytics._parse_amount(t.get('Amount', 0))
                if amount > 0:
                    monthly[month_key].income += amount
                elif amount < 0:
                    monthly[month_key].expense += abs(amount)
                monthly[month_key].count += 1
                
            except Exception as e:
                logger.warning(f"Failed to process transaction for monthly summary: {e}")
                continue
        
        return monthly
    
    @staticmethod
    def get_category_breakdown(transactions: List[Dict]) -> List[CategoryBreakdown]:
        """Get category breakdown for expenses."""
        categories = defaultdict(float)
        total_expense = 0
        
        for t in transactions:
            try:
                amount = FinancialAnalytics._parse_amount(t.get('Amount', 0))
                if amount < 0:
                    category = t.get('Category', 'Lainnya')
                    if not category or category == '':
                        category = 'Lainnya'
                    categories[category] += abs(amount)
                    total_expense += abs(amount)
            except Exception as e:
                logger.warning(f"Failed to process category breakdown: {e}")
                continue
        
        result = []
        if total_expense > 0:
            for category, amount in categories.items():
                percentage = (amount / total_expense * 100)
                result.append(CategoryBreakdown(
                    category=category,
                    amount=amount,
                    percentage=percentage
                ))
        else:
            for category, amount in categories.items():
                result.append(CategoryBreakdown(
                    category=category,
                    amount=amount,
                    percentage=0
                ))
        
        result.sort(key=lambda x: x.amount, reverse=True)
        return result
    
    @staticmethod
    def get_monthly_comparison(transactions: List[Dict]) -> Dict:
        """Compare current month with previous month."""
        current_date = now()
        current_month = current_date.strftime('%Y-%m')
        prev_month = (current_date.replace(day=1) - timedelta(days=1)).strftime('%Y-%m')
        
        monthly = FinancialAnalytics.get_monthly_summary(transactions)
        
        result = {
            'current': monthly.get(current_month),
            'previous': monthly.get(prev_month),
            'has_data': current_month in monthly and prev_month in monthly
        }
        
        if result['has_data']:
            current = result['current']
            previous = result['previous']
            
            income_change = ((current.income - previous.income) / previous.income * 100) if previous.income > 0 else 0
            expense_change = ((current.expense - previous.expense) / previous.expense * 100) if previous.expense > 0 else 0
            
            result['comparison'] = {
                'income_change': income_change,
                'expense_change': expense_change,
                'net_change': current.net - previous.net,
            }
        
        return result
    
    @staticmethod
    def generate_insights(transactions: List[Dict], summary: FinancialSummary) -> List[FinancialInsight]:
        """Generate financial insights from transactions."""
        insights = []
        
        if not transactions or len(transactions) < 3:
            insights.append(FinancialInsight(
                type='info',
                message="Mulai catat transaksi untuk mendapatkan insight keuangan."
            ))
            return insights
        
        categories = FinancialAnalytics.get_category_breakdown(transactions)
        if categories:
            top = categories[0]
            if top.amount > 0:
                insights.append(FinancialInsight(
                    type='info',
                    message=f"Pengeluaran terbesar dari *{top.category}*: Rp {top.amount:,.0f}",
                    emoji='🍽️'
                ))
        
        if summary.savings_rate > 0:
            if summary.savings_rate >= 30:
                insights.append(FinancialInsight(
                    type='success',
                    message=f"*Sangat baik!* Tingkat tabungan: {summary.savings_rate:.0f}%",
                    emoji='💪'
                ))
            elif summary.savings_rate >= 20:
                insights.append(FinancialInsight(
                    type='success',
                    message=f"*Baik!* Tingkat tabungan: {summary.savings_rate:.0f}%",
                    emoji='✅'
                ))
            elif summary.savings_rate >= 10:
                insights.append(FinancialInsight(
                    type='info',
                    message=f"*Cukup* Tingkat tabungan: {summary.savings_rate:.0f}%",
                    emoji='📈'
                ))
            else:
                insights.append(FinancialInsight(
                    type='warning',
                    message=f"Tingkat tabungan rendah ({summary.savings_rate:.0f}%). Coba kurangi pengeluaran.",
                    emoji='⚠️'
                ))
        
        comparison = FinancialAnalytics.get_monthly_comparison(transactions)
        if comparison.get('has_data'):
            expense_change = comparison['comparison']['expense_change']
            if expense_change > 20:
                insights.append(FinancialInsight(
                    type='warning',
                    message=f"Pengeluaran naik {expense_change:.1f}% dibanding bulan lalu",
                    emoji='⚠️'
                ))
            elif expense_change < -20:
                insights.append(FinancialInsight(
                    type='success',
                    message=f"Pengeluaran turun {abs(expense_change):.1f}% dibanding bulan lalu",
                    emoji='✅'
                ))
            elif abs(expense_change) <= 5:
                insights.append(FinancialInsight(
                    type='info',
                    message="Pengeluaran stabil dibanding bulan lalu",
                    emoji='📊'
                ))
        
        return insights