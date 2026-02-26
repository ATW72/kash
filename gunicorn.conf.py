# Gunicorn configuration for Kash
# https://docs.gunicorn.org/en/stable/configure.html

# Server socket
bind = "0.0.0.0:5000"

# Worker processes
# Recommended: (2 x CPU cores) + 1
# For a 1-core LXC this gives 3 workers
workers = 3
worker_class = "sync"
worker_connections = 1000
timeout = 300
keepalive = 5

# Restart workers after this many requests (prevents memory leaks)
max_requests = 1000
max_requests_jitter = 100

# Logging
accesslog = "-"   # stdout → systemd journal
errorlog  = "-"   # stderr → systemd journal
loglevel  = "info"
access_log_format = '%(h)s "%(r)s" %(s)s %(b)s %(D)sµs'

# Process naming
proc_name = "kash"

# Graceful timeout on shutdown
graceful_timeout = 30
