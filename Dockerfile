FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (minimal untuk Python)
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY data/ ./data/

# Create directories
RUN mkdir -p /app/data /app/logs

# ============================================================
# PERBAIKAN: Health file dibuat oleh aplikasi, bukan di sini
# ============================================================
# Kita tidak perlu touch /app/health di sini karena aplikasi akan membuatnya

# Set Python path
ENV PYTHONPATH=/app
ENV TZ=Asia/Jakarta

# ============================================================
# PERBAIKAN: Hapus HEALTHCHECK dari Dockerfile
# ============================================================
# Healthcheck akan didefinisikan di docker-compose.yml
# agar lebih fleksibel dan mudah diubah tanpa rebuild image

# Run the bot
CMD ["python", "-m", "src.main"]