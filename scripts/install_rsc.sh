#!/bin/bash

set -xe

export DEBIAN_FRONTEND=noninteractive

RSC_VERSION=${RSC_VERSION:-1.8.0.4-21}
RSC_USERNAME=${RSC_USERNAME:-rstudio}
RSC_PASSWORD=${RSC_PASSWORD:-rstudio}

# Install RSC
apt-get update
apt-get install -y gdebi-core
curl -o /tmp/rstudio-connect_${RSC_VERSION}_amd64.deb https://s3.amazonaws.com/rstudio-connect/rstudio-connect_${RSC_VERSION}_amd64.deb
gdebi --non-interactive /tmp/rstudio-connect_${RSC_VERSION}_amd64.deb
rm /tmp/rstudio-connect_${RSC_VERSION}_amd64.deb

# Configure RSC
cat >/etc/rstudio-connect/rstudio-connect.gcfg <<EOL
; RStudio Connect configuration file

; Address is a public URL for this RStudio Connect server. Must be configured
; to enable features like including links to your content in emails. If
; Connect is deployed behind an HTTP proxy, this should be the URL for Connect
; in terms of that proxy.
;
; Address = https://rstudio-connect.company.com
[Server]
; Address = RSC_SERVER_ADDRESS

[HTTP]
Listen = :80

[Authentication]
Provider = password

[Database]
Provider = sqlite

[Python]
Enabled = true
Executable = /opt/python/3.7.3/bin/python
Executable = /opt/python/2.7.16/bin/python

;[RPackageRepository "CRAN"]
;URL = RSPM_SERVER_ADDRESS

;[RPackageRepository "RSPM"]
;URL = RSPM_SERVER_ADDRESS
EOL

RSC_CONFIG_FILE=/etc/rstudio-connect/rstudio-connect.gcfg

if [[ ! -z "${RSPM_ADDRESS}" ]]; then
    sed -i -e 's|;\[RPackageRepository "CRAN"\]|\[RPackageRepository "CRAN"\]|' $RSC_CONFIG_FILE
    sed -i -e 's|;\[RPackageRepository "RSPM"\]|\[RPackageRepository "RSPM"\]|' $RSC_CONFIG_FILE
    sed -i -e "s|;URL = RSPM_SERVER_ADDRESS|URL = ${RSPM_ADDRESS}/cran/__linux__/bionic/latest|" $RSC_CONFIG_FILE
fi

# Restart service
systemctl restart rstudio-connect

bash ./wait-for-it.sh localhost:80 -t 60

# Create connect admin user
curl -i -X POST -d "{\"email\": \"rstudio@example.com\", \"username\": \"${RSC_USERNAME}\", \"password\": \"${RSC_PASSWORD}\"}" localhost:80/__api__/v1/users