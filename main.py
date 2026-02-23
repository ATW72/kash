from app import app, init_db
from config.settings import Config
from utils.notifications import init_mail

# Always runs whether started by Gunicorn or directly
init_db()
init_mail(app)

# Load mail settings from Config into Flask app config
app.config['MAIL_SERVER']   = 'smtp.gmail.com'
app.config['MAIL_PORT']     = 587
app.config['MAIL_USE_TLS']  = True
app.config['MAIL_USERNAME'] = Config.MAIL_USERNAME
app.config['MAIL_PASSWORD'] = Config.MAIL_PASSWORD
app.config['MAIL_FROM_NAME'] = Config.MAIL_FROM_NAME

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=Config.PORT, debug=Config.DEBUG)
