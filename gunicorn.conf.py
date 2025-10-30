"""Gunicorn configuration for Docker deployment"""

# Server socket - bind to different port for nginx upstream
bind = "127.0.0.1:8001"

# Worker processes
workers = 2
worker_class = "sync"
worker_connections = 1000
max_requests = 10000
max_requests_jitter = 1000

# Timeouts
timeout = 300
keepalive = 5
graceful_timeout = 30

# Logging to stdout/stderr
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "django_api"

# Server mechanics
daemon = False
umask = 0o007
tmp_upload_dir = None

# Security
limit_request_line = 8190
limit_request_fields = 100
limit_request_field_size = 8190

# Preload app for better performance
preload_app = True
