"""Tests for parsers"""

import pytest
from datetime import datetime
from src.utils.parsers import parse_indonesian_amount, parse_transaction_locally, parse_date_from_text
from src.utils.timezone import now, today, yesterday, tomorrow, JAKARTA_TZ


class TestParsers:
    """Test parsers."""
    
    def test_parse_indonesian_amount(self):
        """Test Indonesian amount parsing."""
        assert parse_indonesian_amount("50000") == 50000
        assert parse_indonesian_amount("50k") == 50000
        assert parse_indonesian_amount("50rb") == 50000
        assert parse_indonesian_amount("1jt") == 1000000
        assert parse_indonesian_amount("1.5jt") == 1500000
        assert parse_indonesian_amount("1,5jt") == 1500000
        assert parse_indonesian_amount("100rb") == 100000
        assert parse_indonesian_amount("1.500.000") == 1500000
        assert parse_indonesian_amount("1,500,000") == 1500000
    
    def test_parse_transaction_locally(self):
        """Test local transaction parsing."""
        result = parse_transaction_locally("Beli makan siang 50000")
        assert result['amount'] == -50000
        assert result['transaction_type'] == 'expense'
        assert 'makan' in result['description'].lower()
        
        result = parse_transaction_locally("Terima gaji 5000000")
        assert result['amount'] == 5000000
        assert result['transaction_type'] == 'income'
        assert 'gaji' in result['description'].lower()
    
    def test_parse_date_from_text(self):
        """Test date parsing using Jakarta timezone."""
        current_date = now()
        today_str = today()
        yesterday_str = yesterday()
        
        assert parse_date_from_text("kemarin") == yesterday_str
        assert parse_date_from_text("hari ini") == today_str
        
        # Test with specific date
        result = parse_date_from_text("2024-01-15")
        assert result == "2024-01-15"
    
    def test_timezone_consistency(self):
        """Test that timezone is consistent."""
        current = now()
        # Should have Asia/Jakarta timezone
        assert current.tzinfo == JAKARTA_TZ
        
        # Today should match current date
        assert today() == current.strftime("%Y-%m-%d")
    
    def test_parse_just_amount(self):
        """Test parsing just an amount without context."""
        # "5jt" without context should not auto-detect as expense
        result = parse_transaction_locally("5jt")
        # Should have amount but transaction_type should be expense (default)
        assert result['amount'] == 5000000
        # But we should not assume income
        # The UI will ask for clarification