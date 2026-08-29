# ============================================================
# TELEGRAM FINANCE BOT - DOCKERFILE
# ============================================================

FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Buat user non-root untuk keamanan
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser

WORKDIR /app

# Copy requirements dan install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Set ownership ke appuser
RUN chown -R appuser:appuser /app

# Switch ke user non-root
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Jalankan bot
CMD ["python", "src/main.py"]
