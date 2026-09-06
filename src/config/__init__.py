"""Configuration module"""

from src.config.settings import settings
from src.config.constants import *

__all__ = [
    'settings',
    'CATEGORY_EMOJIS',
    'INCOME_KEYWORDS',
    'EXPENSE_KEYWORDS',
    'CATEGORY_MAP',
    'STATE_WAITING_AMOUNT',
    'STATE_WAITING_CONFIRMATION',
    'STATE_WAITING_DATE',
]