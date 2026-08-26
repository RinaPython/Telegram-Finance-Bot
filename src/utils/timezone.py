"""Timezone utilities for Asia/Jakarta"""

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from typing import Optional

# Jakarta timezone
JAKARTA_TZ = ZoneInfo("Asia/Jakarta")


def now() -> datetime:
    """Get current datetime in Asia/Jakarta timezone."""
    return datetime.now(JAKARTA_TZ)


def today() -> str:
    """Get today's date in YYYY-MM-DD format in Asia/Jakarta timezone."""
    return now().strftime("%Y-%m-%d")


def today_display() -> str:
    """Get today's date in display format in Asia/Jakarta timezone."""
    return now().strftime("%d/%m/%Y")


def yesterday() -> str:
    """Get yesterday's date in YYYY-MM-DD format in Asia/Jakarta timezone."""
    return (now() - timedelta(days=1)).strftime("%Y-%m-%d")


def tomorrow() -> str:
    """Get tomorrow's date in YYYY-MM-DD format in Asia/Jakarta timezone."""
    return (now() + timedelta(days=1)).strftime("%Y-%m-%d")


def format_date(date_str: str, input_format: str = "%Y-%m-%d", output_format: str = "%d/%m/%Y") -> str:
    """Format date string from one format to another."""
    try:
        dt = datetime.strptime(date_str, input_format)
        return dt.strftime(output_format)
    except (ValueError, TypeError):
        return date_str


def parse_date(date_str: str) -> Optional[datetime]:
    """Parse date string to datetime object."""
    formats = ["%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y", "%d.%m.%Y"]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    return None


def get_current_month() -> str:
    """Get current month in YYYY-MM format in Asia/Jakarta timezone."""
    return now().strftime("%Y-%m")


def get_current_month_name() -> str:
    """Get current month name in Asia/Jakarta timezone."""
    return now().strftime("%B")


def get_current_year() -> str:
    """Get current year in Asia/Jakarta timezone."""
    return now().strftime("%Y")


def get_previous_month() -> str:
    """Get previous month in YYYY-MM format in Asia/Jakarta timezone."""
    current = now()
    if current.month == 1:
        year = current.year - 1
        month = 12
    else:
        year = current.year
        month = current.month - 1
    return f"{year:04d}-{month:02d}"


def get_month_range(month: str) -> tuple:
    """Get start and end dates for a month in YYYY-MM format."""
    year, month_num = map(int, month.split('-'))
    
    # First day of month
    start = datetime(year, month_num, 1, tzinfo=JAKARTA_TZ)
    
    # Last day of month
    if month_num == 12:
        end = datetime(year + 1, 1, 1, tzinfo=JAKARTA_TZ) - timedelta(days=1)
    else:
        end = datetime(year, month_num + 1, 1, tzinfo=JAKARTA_TZ) - timedelta(days=1)
    
    return start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d")


def get_timestamp() -> str:
    """Get current timestamp in Asia/Jakarta timezone."""
    return now().strftime("%Y-%m-%d %H:%M:%S")


def is_today(date_str: str) -> bool:
    """Check if date string is today in Asia/Jakarta timezone."""
    return date_str == today()


def is_this_month(month_str: str) -> bool:
    """Check if month string is current month in Asia/Jakarta timezone."""
    return month_str == get_current_month()