FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install procps for pgrep healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends procps && \
    rm -rf /var/lib/apt/lists/*

# Copy application
COPY . .

# Create necessary directories
RUN mkdir -p /app/data /app/logs /app/secrets

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Create healthcheck file
RUN touch /app/health

# HEALTHCHECK - Memeriksa apakah bot process berjalan
# Menggunakan file health yang diupdate oleh bot setiap 30 detik
# Dan memeriksa apakah process python masih berjalan
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD sh -c ' \
        if [ -f /app/health ]; then \
            MOD_TIME=$(stat -c %Y /app/health 2>/dev/null || stat -f %m /app/health 2>/dev/null); \
            NOW=$(date +%s); \
            if [ $((NOW - MOD_TIME)) -lt 60 ]; then \
                if pgrep -f "python.*main.py" > /dev/null; then \
                    exit 0; \
                fi; \
            fi; \
        fi; \
        exit 1; \
    '

CMD ["python", "src/main.py"]