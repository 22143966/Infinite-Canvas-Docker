FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Run the server as a non-root user; the entrypoint drops privileges at startup.
RUN useradd --create-home --shell /usr/sbin/nologin appuser

# Lightweight deps only (fastapi/uvicorn/requests/pydantic/pillow/httpx) — no ML libs.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Application source: main.py + committed static frontend + bundled helpers.
COPY main.py ./
COPY . .

# Runtime entrypoint (placed into the build context by build.yml) handles
# directory creation, file defaults, symlinks and ownership before exec.
COPY docker-entrypoint.py /usr/local/bin/docker-entrypoint.py

RUN mkdir -p API data assets/input assets/output assets/library output workflows/custom \
    && sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.py \
    && chmod +x /usr/local/bin/docker-entrypoint.py \
    && chown -R appuser:appuser /app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:3000/api/app-info', timeout=3).read()" || exit 1

ENTRYPOINT ["docker-entrypoint.py"]
CMD ["python", "main.py"]
