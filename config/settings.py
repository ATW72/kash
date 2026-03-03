import os
import secrets

class Config:
    SECRET_KEY = os.environ.get('FLASK_SECRET_KEY') or secrets.token_hex(32)
    DATABASE_PATH = os.environ.get('APP_DATABASE_PATH', os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'expenses.db'))
    HOST = os.environ.get('APP_HOST', '0.0.0.0')
    PORT = int(os.environ.get('APP_PORT', 5000))
    DEBUG = os.environ.get('APP_DEBUG', 'false').lower() == 'true'
    ADMIN_USERNAME = os.environ.get('APP_LOGIN_USERNAME')
    ADMIN_PASSWORD = os.environ.get('APP_LOGIN_PASSWORD')
    SESSION_COOKIE_SECURE = os.environ.get('SESSION_COOKIE_SECURE', 'false').lower() == 'true'
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    PERMANENT_SESSION_LIFETIME = 86400  # 24 hours

    # Mail settings
    MAIL_SERVER = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'true').lower() == 'true'
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME', '')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD', '')
    MAIL_FROM_NAME = os.environ.get('MAIL_FROM_NAME', 'Kash')
    MAIL_ENABLED = bool(os.environ.get('MAIL_USERNAME', ''))

    # Ollama
    OLLAMA_URL   = os.environ.get('OLLAMA_URL', '')
    OLLAMA_MODEL = os.environ.get('OLLAMA_MODEL', 'llama3.1:8b')
    # OAuth
    GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
    GOOGLE_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')
