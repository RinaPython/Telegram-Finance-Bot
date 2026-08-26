"""Financial summary data models"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class FinancialSummary:
    """Overall financial summary."""
    total_income: float = 0
    total_expense: float = 0
    net_profit: float = 0
    savings_rate: float = 0
    total_transactions: int = 0
    income_count: int = 0
    expense_count: int = 0
    
    def to_dict(self) -> dict:
        return {
            'total_income': self.total_income,
            'total_expense': self.total_expense,
            'net_profit': self.net_profit,
            'savings_rate': self.savings_rate,
            'total_transactions': self.total_transactions,
            'income_count': self.income_count,
            'expense_count': self.expense_count
        }


@dataclass
class MonthlySummary:
    """Monthly summary data."""
    month: str
    month_name: str
    income: float = 0
    expense: float = 0
    count: int = 0
    
    @property
    def net(self) -> float:
        return self.income - self.expense
    
    @property
    def savings_rate(self) -> float:
        return (self.net / self.income * 100) if self.income > 0 else 0


@dataclass
class CategoryBreakdown:
    """Category breakdown data."""
    category: str
    amount: float
    percentage: float


@dataclass
class FinancialInsight:
    """Financial insight."""
    type: str  # 'warning', 'info', 'success'
    message: str
    emoji: str = '💡'