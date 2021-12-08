SECRET_KEY = 'pickabettersecret'

APP_NAME = 'Moby Dock'

DEBUG = True
TESTING = False

SQLALCHEMY_DATABASE_URI = 'postgresql://mobydock:yourpassword@postgres:5432/mobydock'
REDIS_URL = 'redis://redis:6379/0'

# I added this at the last minute to suppress the warning from SQLAlchemy.
SQLALCHEMY_TRACK_MODIFICATIONS = False