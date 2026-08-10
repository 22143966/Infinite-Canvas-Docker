# Infinite-Canvas (hero8152 fork) — Docker image
# Lightweight FastAPI app. All heavy compute (e.g. local ComfyUI) runs elsewhere
# on your LAN or in the cloud; this container only relays requests + serves the UI.

FROM python:3.11-slim

# Non-interactive, clean Python runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install Python deps first so this layer is cached across source changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source.
# The bundled portable Python (python/), offline package cache (packages/),
# and platform launch scripts are EXCLUDED via .dockerignore.
COPY . .

# Ensure persistence directories exist (the app also creates them at runtime)
RUN mkdir -p data output assets workflows API

EXPOSE 3000

# main.py already binds 0.0.0.0:3000 (no --host override needed)
CMD ["python3", "main.py"]
