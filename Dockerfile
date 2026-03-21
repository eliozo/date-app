# syntax=docker/dockerfile:1.7

ARG PYTHON_VERSION=3.12

# 1) Builder stage: build wheels
FROM python:${PYTHON_VERSION}-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


# 2) Runtime stage: minimal image with only runtime dependencies and app code
FROM python:${PYTHON_VERSION}-slim AS runtime

# Build arguments for non-root user
ARG APP_UID=10001
ARG APP_GID=10001

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Create non-root user/group
RUN groupadd -g ${APP_GID} appgroup && \
    useradd  -u ${APP_UID} -g ${APP_GID} -m -s /usr/sbin/nologin appuser

COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache-dir /wheels/* && \
    rm -rf /wheels

COPY app.py .
COPY templates/ templates/

RUN chown -R ${APP_UID}:${APP_GID} /app

USER ${APP_UID}:${APP_GID}

EXPOSE 5000

# Entrypoint / command: use gunicorn for production-grade WSGI server
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]