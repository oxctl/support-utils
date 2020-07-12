#!/bin/bash
# This updates the discovery URL on test/beta.

if [ "$1" == "" ]; then
  echo Usage: $(basename $0) config-file.env
  exit 1;
fi

file="$1"

# Check the config is ok.
if [ ! -f "$file" ]; then
  echo Cannot find config file: $file
  exit 1
fi

# Actually load config
source "${file}"

if [ -z "${host}" ] || [ -z "${token}" ] || [ -z "${login_url}" ]; then 
  echo "You must set host, token and login_url for this to work."
  exit 1
fi

# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)

curl -X PUT -f \
  -o /dev/null -s \
  https://$host/api/v1/accounts/1/sso_settings \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer $token" \
  -H 'Cache-Control: no-cache' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' \
  -F "sso_settings[auth_discovery_url=$login_url"

code=$?
if [ $code -ne 0 ]; then
  if [ $code -eq 22 ]; then
    echo "Login failed for: $host check token is invalid"
  else
    echo "Failed to update login page for: $host"
  fi
  exit 1
fi


