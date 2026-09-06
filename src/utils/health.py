"""Health check utilities"""

import os
import time
from pathlib import Path

HEALTH_FILE = "/app/health"


def update_health_file():
    """Update health file dengan timestamp."""
    try:
        # Buat direktori jika belum ada
        os.makedirs(os.path.dirname(HEALTH_FILE), exist_ok=True)
        with open(HEALTH_FILE, 'w') as f:
            f.write(f"healthy:{time.time()}")
        return True
    except Exception:
        return False


def is_healthy(timeout_seconds: int = 300) -> bool:
    """
    Cek apakah bot sehat.
    
    Args:
        timeout_seconds: Maksimal umur file health (detik)
    
    Returns:
        True jika file health ada dan masih fresh
    """
    if not os.path.exists(HEALTH_FILE):
        return False
    
    try:
        mtime = os.path.getmtime(HEALTH_FILE)
        return (time.time() - mtime) < timeout_seconds
    except Exception:
        return False