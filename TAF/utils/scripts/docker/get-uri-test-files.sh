#!/bin/sh

GITHUB_URL="https://raw.githubusercontent.com/edgexfoundry"
UOM_URL="${GITHUB_URL}/edgex-go/main/cmd/core-metadata/res"
HTTP_SERVER_DIR='http://${HTTP_USER}:${HTTP_PASSWD}@httpd-auth:80/file'

# Download files to test URI for files
cd ../../../testData/httpd
## UOM file
curl -o uom.yaml ${GITHUB_URL}/edgex-go/main/cmd/core-metadata/res/uom.yaml

# Update UoM file
sed -i '$a\ \ \ \ \ \ -\ uritest' uom.yaml

## device-onvif-camera files
ONVIF_URL="${GITHUB_URL}/device-onvif-camera/main/cmd/res"
curl -o config.yaml ${ONVIF_URL}/configuration.yaml
curl -o profile.yaml ${ONVIF_URL}/profiles/camera.yaml
curl -o device.yaml ${ONVIF_URL}/devices/camera.yaml.example
curl -o prowatcher.yaml ${ONVIF_URL}/provisionwatchers/generic.provision.watcher.yaml

# Update onvif-camera configuration file
#sed -i "s/.\/res\/profiles/${HTTP_SERVER_DIR}\/profile.json/g" config.yaml
#sed -i "s/.\/res\/devices/${HTTP_SERVER_DIR}\/device.json/g" config.yaml
#sed -i "s/.\/res\/provisionwatchers/${HTTP_SERVER_DIR}\/provisionwatcher.json/g" config.yaml

# Update onvif-camera sample files
sed -i '/labels:/a \ \ -\ \"uritest\"' profile.yaml
sed -i '/description:/ s/$/\ -\ uritest/' device.yaml
sed -i '/serviceName:/a labels:' prowatcher.yaml
sed -i '/labels:/a \ \ -\ uritest' prowatcher.yaml
