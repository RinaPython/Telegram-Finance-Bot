"""Finance Bot - Personal Finance Tracking with AI"""

__version__ = "4.0.0"
__author__ = "Finance Bot Team"
__description__ = "Telegram bot for personal finance management with AI"

from src.config.settings import settings
from src.utils.logger import logger

__all__ = [
    'settings',
    'logger',
    '__version__',
    '__author__',
]