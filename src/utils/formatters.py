"""Formatting utilities"""

import re
from src.config.constants import CATEGORY_EMOJIS


def format_rupiah(amount: float) -> str:
    """Format amount with Rupiah and thousand separators."""
    return f"Rp {amount:,.0f}".replace(',', '.')


def get_category_emoji(category: str) -> str:
    """Get emoji for a category, with fallback to default."""
    return CATEGORY_EMOJIS.get(category, '📦')


def mask_sensitive(data: str, show: int = 4) -> str:
    """Mask sensitive data showing only first and last characters."""
    if not data:
        return "NOT SET"
    if len(data) <= 8:
        return "****"
    return data[:show] + '...' + data[-show:]


def escape_markdown(text: str) -> str:
    """
    Escape Markdown special characters in text.
    Characters: _ * [ ] ( ) ~ ` > # + - = | { } . !
    """
    # ============================================================
    # PERBAIKAN: HANDLE NONE TYPE
    # ============================================================
    if text is None:
        return ""
    if not text:
        return ""
    escape_chars = r'_*[]()~`>#+-=|{}.!'
    return re.sub(f'([{re.escape(escape_chars)}])', r'\\\1', str(text))


def safe_markdown_text(text: str, parse_mode: str = 'Markdown') -> str:
    """
    Safely format text for Markdown.
    If parse_mode is None, return plain text.
    """
    if parse_mode is None:
        return text
    return escape_markdown(text)


def format_transaction(transaction: dict) -> str:
    """Format a transaction for display."""
    amount = float(transaction.get('Amount', 0))
    category = transaction.get('Category', 'Lainnya')
    description = transaction.get('Description', '')
    date = transaction.get('Date', '')
    emoji = get_category_emoji(category)
    
    sign = "💰" if amount > 0 else "💸"
    formatted_amount = format_rupiah(abs(amount))
    
    return f"{date} {sign} {emoji} {category}\n{formatted_amount} - {description}"
