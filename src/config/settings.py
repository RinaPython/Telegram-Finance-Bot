"""Configuration management"""

import os
import re
from typing import List, Optional
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)


class Settings:
    TELEGRAM_TOKEN: str = os.getenv('TELEGRAM_TOKEN', '')
    GEMINI_API_KEY: str = os.getenv('GEMINI_API_KEY', '')
    
    _raw_authorized_users: str = os.getenv('AUTHORIZED_USER_ID', '')
    AUTHORIZED_USER_IDS: List[str] = [
        uid.strip() for uid in _raw_authorized_users.split(',') 
        if uid.strip() and uid.strip().isdigit()
    ]
    
    SPREADSHEET_ID: str = os.getenv('SPREADSHEET_ID', '')
    GOOGLE_SHEETS_CREDENTIALS: str = os.getenv('GOOGLE_SHEETS_CREDENTIALS', '')
    GOOGLE_SHEETS_CREDENTIALS_JSON: str = os.getenv('GOOGLE_SHEETS_CREDENTIALS_JSON', '')
    
    BOT_VERSION: str = "v1.0.0"
    GEMINI_MODEL: str = 'models/gemini-2.5-flash-lite'
    
    _raw_history_page_size: str = os.getenv('HISTORY_PAGE_SIZE', '5')
    try:
        HISTORY_PAGE_SIZE: int = int(_raw_history_page_size)
        if HISTORY_PAGE_SIZE <= 0:
            HISTORY_PAGE_SIZE = 5
    except (ValueError, TypeError):
        HISTORY_PAGE_SIZE = 5
    
    DELETE_MESSAGES: bool = os.getenv('DELETE_MESSAGES', 'true').lower() == 'true'
    USE_GOOGLE_SHEETS: bool = False
    
    @classmethod
    def is_authorized(cls, user_id: int) -> bool:
        return str(user_id) in cls.AUTHORIZED_USER_IDS
    
    @classmethod
    def is_google_sheets_enabled(cls) -> bool:
        return bool(cls.SPREADSHEET_ID and 
                   (cls.GOOGLE_SHEETS_CREDENTIALS_JSON or cls.GOOGLE_SHEETS_CREDENTIALS))
    
    @classmethod
    def is_gemini_enabled(cls) -> bool:
        return bool(cls.GEMINI_API_KEY)
    
    @classmethod
    def get_spreadsheet_id(cls) -> Optional[str]:
        if not cls.SPREADSHEET_ID:
            return None
        if len(cls.SPREADSHEET_ID) == 44 and not cls.SPREADSHEET_ID.startswith('http'):
            return cls.SPREADSHEET_ID
        if 'docs.google.com/spreadsheets/d/' in cls.SPREADSHEET_ID:
            match = re.search(r'/d/([a-zA-Z0-9-_]+)', cls.SPREADSHEET_ID)
            if match:
                return match.group(1)
        return cls.SPREADSHEET_ID


settings = Settings()


# Import logger after settings to avoid circular import
from src.utils.logger import logger
