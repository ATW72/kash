from app import app, init_db
from config.settings import Config
from utils.notifications import init_mail

# Always runs whether started by Gunicorn or directly
init_db()

# Load mail settings from Config into Flask app BEFORE init_mail
app.config['MAIL_SERVER']         = 'smtp.gmail.com'
app.config['MAIL_PORT']           = 587
app.config['MAIL_USE_TLS']        = True
app.config['MAIL_USERNAME']       = Config.MAIL_USERNAME
app.config['MAIL_PASSWORD']       = Config.MAIL_PASSWORD
app.config['MAIL_FROM_NAME']      = Config.MAIL_FROM_NAME
app.config['MAIL_DEFAULT_SENDER'] = (Config.MAIL_FROM_NAME, Config.MAIL_USERNAME)

# Now init mail with correct config already in place
init_mail(app)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=Config.PORT, debug=Config.DEBUG)
