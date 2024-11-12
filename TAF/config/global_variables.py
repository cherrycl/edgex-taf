import os

LOG_LEVEL = "INFO"

# Release Version
REL_MAJOR_VERSION = "4.0"

# API Version
API_VERSION = "v3"

# Deploy type: docker, manual
DEPLOY_TYPE = "docker"
SERVICE_STARTUP_RECHECK_TIMES = 10
SERVICE_STARTUP_WAIT_TIME = 3

# EdgeX host
BASE_URL = "localhost"

# OS environment variables
SECURITY_SERVICE_NEEDED=os.getenv("SECURITY_SERVICE_NEEDED")
DOCKER_HOST_IP=os.getenv("DOCKER_HOST_IP")
ARCH=os.getenv("ARCH")
REGISTRY_SERVICE=os.getenv("REGISTRY_SERVICE")

# Token related variables
jwt_token = ''

# Service port
APP_SAMPLE_PORT=59700
APP_HTTP_EXPORT_PORT = 59704
APP_MQTT_EXPORT_PORT = 59703
APP_FUNCTIONAL_TESTS_PORT = 59705
APP_EXTERNAL_MQTT_TRIGGER_PORT = 59706
EX_BROKER_PORT = 1884
BROKER_PORT = 1883

# Registry Config Version
CONFIG_VERSION = "v4"

if SECURITY_SERVICE_NEEDED == 'true':
    URI_SCHEME = "https"
    CORE_DATA_PORT = "8443/core-data"
    CORE_METADATA_PORT = "8443/core-metadata"
    CORE_COMMAND_PORT = "8443/core-command"
    CORE_KEEPER_PORT = "8443/core-keeper"
    SUPPORT_NOTIFICATIONS_PORT = "8443/support-notifications"
    RULESENGINE_PORT = "8443/rules-engine"
    ONVIF_CAMERA_PORT = "8443/device-onvif-camera"
    SUPPORT_SCHEDULER_PORT = "8443/support-scheduler"
else:
    URI_SCHEME = "http"
    CORE_DATA_PORT = 59880
    CORE_METADATA_PORT = 59881
    CORE_COMMAND_PORT = 59882
    CORE_KEEPER_PORT = 59890
    SUPPORT_NOTIFICATIONS_PORT = 59860
    RULESENGINE_PORT = 59720
    ONVIF_CAMERA_PORT = 59984
    SUPPORT_SCHEDULER_PORT = 59863


# External MQTT Auth
EX_BROKER_USER = os.getenv("EX_BROKER_USER")
EX_BROKER_PASSWD = os.getenv("EX_BROKER_PASSWD")

# HTTP Server Auth
HTTP_USER = os.getenv("HTTP_USER")
HTTP_PASSWD = os.getenv("HTTP_PASSWD")
