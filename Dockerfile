FROM ubuntu:24.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set Python to not buffer stdout/stderr
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Аргументы сборки
ARG GITHUB_REPO
ARG REPO_NAME
ARG CACHEBUST=1
ENV REACT_MODULES_BUST=1
ENV SERVER_MODULES_BUST=1

# Set working directory
WORKDIR /app

# Устанавливаем Git (используем apt вместо apk)
RUN apt-get update && apt-get install -y git

# Клонируем репозиторий
RUN echo "Cache bust: $CACHEBUST $(date)" && \
    git clone ${GITHUB_REPO} ${REPO_NAME}

# Переходим в директорию React приложения
WORKDIR /usr/src/app/${REPO_NAME}/react

# Устанавливаем зависимости для React
RUN if [ "$REACT_MODULES_BUST" = "1" ]; then \
        echo "Forcing React modules reinstall"; \
        rm -rf node_modules; \
        npm install; \
    else \
        if [ -d "node_modules" ]; then \
            echo "Using existing React modules"; \
        else \
            echo "Installing React modules"; \
            npm install; \
        fi; \
    fi

# Собираем React приложение
RUN npm run build

# Переходим в директорию сервера
WORKDIR /usr/src/app/${REPO_NAME}/server

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3-pip \
    python3-venv \
    build-essential \
    libpq-dev \
    nginx \
    supervisor \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements first for better caching
COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code from server folder
COPY server/ .

# Collect static files
RUN python manage.py collectstatic --noinput

# Copy nginx configuration from server/nginx
COPY server/nginx/nginx.conf /etc/nginx/nginx.conf
COPY server/nginx/django-api.conf /etc/nginx/sites-available/default

# Remove default nginx site and setup our config
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy supervisor configuration from server
COPY server/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create non-root user
RUN useradd -m -u 1234 appuser && \
    touch /run/nginx.pid && \
    chown -R appuser:appuser /run/nginx.pid && \
    chown -R appuser:appuser /app

# Expose port
EXPOSE 8080

# Run supervisord
CMD ["/bin/bash", "docker-entrypoint.sh"]