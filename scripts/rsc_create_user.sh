#!/bin/bash
set -ex


RSC_USERNAME=${RSC_USERNAME:-admin}
RSC_PASSWORD=${RSC_PASSWORD:-rstudio}


/usr/local/bin/wait-for-it.sh localhost:80 -t 60

# Create admin user
curl -i -X POST -d "{\"email\": \"rstudio@example.com\", \"username\": \"${RSC_USERNAME}\", \"password\": \"${RSC_PASSWORD}\"}" localhost:80/__api__/v1/users
