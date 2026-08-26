"""Transaction data model"""

import uuid
from dataclasses import dataclass, field
from typing import Optional

from src.utils.timezone import now, get_timestamp


@dataclass
class Transaction:
    """Transaction data model."""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    date: str = None
    amount: float = 0
    category: str = 'Lainnya'
    description: str = ''
    user_id: str = ''
    timestamp: Optional[str] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = get_timestamp()
        if self.date is None:
            self.date = now().strftime("%Y-%m-%d")
    
    def to_row(self) -> list:
        """Convert to Google Sheets row."""
        return [
            self.id,
            self.date,
            self.amount,
            self.category,
            self.description,
            self.user_id,
            self.timestamp
        ]
    
    @classmethod
    def from_row(cls, row: dict) -> 'Transaction':
        """Create from Google Sheets row."""
        return cls(
            id=row.get('ID', str(uuid.uuid4())),
            date=row.get('Date', now().strftime("%Y-%m-%d")),
            amount=float(row.get('Amount', 0)),
            category=row.get('Category', 'Lainnya'),
            description=row.get('Description', ''),
            user_id=str(row.get('User ID', '')),
            timestamp=row.get('Timestamp', get_timestamp())
        )
    
    @property
    def is_income(self) -> bool:
        return self.amount > 0
    
    @property
    def is_expense(self) -> bool:
        return self.amount < 0
    
    @property
    def transaction_type(self) -> str:
        return "Pemasukan" if self.is_income else "Pengeluaran"
    
    @property
    def formatted_amount(self) -> str:
        """Format amount with Rupiah."""
        from src.utils.formatters import format_rupiah
        sign = '+' if self.amount > 0 else '-'
        return f"{sign}{format_rupiah(abs(self.amount))}"
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            'id': self.id,
            'date': self.date,
            'amount': self.amount,
            'category': self.category,
            'description': self.description,
            'user_id': self.user_id,
            'timestamp': self.timestamp
        }