from app import app, init_db
from config.settings import Config

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=Config.PORT, debug=Config.DEBUG)
else:
    init_db()
