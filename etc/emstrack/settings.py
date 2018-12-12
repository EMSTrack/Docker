"""
Django settings for emstrack project.

Generated by 'django-admin startproject' using Django 1.10.1.

For more information on this file, see
https://docs.djangoproject.com/en/1.10/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/1.10/ref/settings/
"""

import os

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Sessions
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
SESSION_COOKIE_AGE = 30 * 60
SESSION_SAVE_EVERY_REQUEST = True

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.10/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = '[secret-key]'

SWAGGER_SETTINGS = {
    'APIS_SORTER': 'alpha',
    'DOC_EXPANSION': 'list',
    'LOGIN_URL': 'rest_framework:login',
    'LOGOUT_URL': 'rest_framework:logout'
}

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = [debug]
ALLOWED_HOSTS = [ [hostname] ]

# Application definition

INSTALLED_APPS = [
    'ambulance.apps.AmbulanceConfig',
    'hospital.apps.HospitalConfig',
    'login.apps.LoginConfig',
    'equipment.apps.EquipmentConfig',
    'mqtt',
    'emstrack',
    'rest_framework',
    'rest_framework_swagger',
    'django_nose',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.gis',
    'jquery',
    'djangoformsetjs',
]

TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'emstrack.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            os.path.join(BASE_DIR, 'templates')
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'emstrack.wsgi.application'


# Database
# https://docs.djangoproject.com/en/1.10/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': '[database]',
        'USER': '[username]',
        'PASSWORD': '[password]',
        'HOST': '[host]',
        'PORT': 5432,
    }
}

# Password validation
# https://docs.djangoproject.com/en/1.10/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/1.10/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.10/howto/static-files/

#STATIC_ROOT = './static/'
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'deploy', 'static')
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'static'),
]

# login redirect
LOGIN_REDIRECT_URL = '/'
LOGIN_URL = '/auth/login'

# email settings
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
DEFAULT_FROM_EMAIL = 'webmaster@cruzroja.ucsd.edu'

# MQTT settings
MQTT = {
    'USERNAME': '[mqtt-username]',
    'PASSWORD': '[mqtt-password]',
    'EMAIL': '[mqtt-email]',
    'CLIENT_ID': '[mqtt-clientid]',
    'BROKER_HOST': '[mqtt-broker-host]',
    'BROKER_PORT': '[mqtt-broker-port]',
    'BROKER_SSL_HOST': '[mqtt-broker-ssl-host]',
    'BROKER_SSL_PORT': '[mqtt-broker-ssl-port]',
    'BROKER_WEBSOCKETS_HOST': '[mqtt-broker-websockets-host]',
    'BROKER_WEBSOCKETS_PORT': '[mqtt-broker-websockets-port]'
}

# Custom user
#AUTH_USER_MODEL = 'ambulance.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.SessionAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    )
}

# Custom message tags
from django.contrib.messages import constants as messages

MESSAGE_TAGS = {
    messages.DEBUG: 'alert-info',
    messages.INFO: 'alert-info',
    messages.SUCCESS: 'alert-success',
    messages.WARNING: 'alert-warning',
    messages.ERROR: 'alert-danger',
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    # 'handlers': {
    #     'file': {
    #         'level': 'DEBUG',
    #         'class': 'logging.FileHandler',
    #         'filename': '/var/log/django/debug.log',
    #     },
    # },
    # 'loggers': {
    #     'django': {
    #         'handlers': ['file'],
    #         'level': 'DEBUG',
    #         'propagate': True,
    #     },
    # },
}
