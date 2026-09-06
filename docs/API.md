# API Documentation

## Google Sheets Integration

### Transactions Sheet
- **Date**: YYYY-MM-DD
- **Amount**: Numeric (positive = income, negative = expense)
- **Category**: String
- **Description**: String
- **User ID**: String
- **Timestamp**: YYYY-MM-DD HH:MM:SS

### PNL Sheet
- **Summary**: Total Income, Total Expense, Net Profit/Loss, Savings Rate, Total Transactions
- **Monthly**: Month, Income, Expense, Net P/L, Savings Rate
- **Category**: Category, Amount, Percentage

## Gemini AI Integration

### Input Format
Natural language text in Indonesian or English:
- "Beli makan siang 50000"
- "Terima gaji 5jt"
- "Bayar listrik 350000"

### Output Format
```json
{
    "amount": 50000,
    "category": "Makanan",
    "description": "Beli makan siang",
    "transaction_type": "expense",
    "date": "2024-01-15"
}