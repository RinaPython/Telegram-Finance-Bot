# ============================================================
# TELEGRAM FINANCE BOT - DOCKERFILE
# ============================================================
# Menggunakan multi-stage build untuk optimasi
# ============================================================

# Stage 1: Builder
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first untuk cache layer
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Buat user non-root untuk keamanan
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser

# Set working directory
WORKDIR /app

# Copy dependencies dari builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy source code
COPY . .

# Set ownership ke appuser
RUN chown -R appuser:appuser /app

# Switch ke user non-root
USER appuser

# Expose port (jika diperlukan untuk health check)
# EXPOSE 8000

# Health check untuk monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Command untuk menjalankan bot
CMD ["python", "src/main.py"]
