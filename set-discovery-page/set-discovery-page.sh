#!/bin/bash
# This replaces the discovery URL on Canvas Beta

# Set flag to quit on error, eg host unavailable
set -e

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

if [ -z "${host}" ] || [ -z "${token}" || -z "${provider_id}" ] ; then 
  echo "You must set host, token  and provider_id for this to work."
  exit 1
fi


# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)

# we change the login route to be https://${host}/login/saml/${provider_id}
printf "Setting 'discovery URL' to be https://${host}/login/saml/${provider_id}\n"

# See: https://canvas.instructure.com/doc/api/authentication_providers.html#method.authentication_providers.update_sso_settings
curl -XPUT "https://${host}/api/v1/accounts/1/sso_settings" -s -H "Authorization: Bearer ${token}"  \
     -F "sso_settings[auth_discovery_url]=https://${host}/login/saml/${provider_id}" | jq || (printf "Unable to set Discovery URL\n\n"; exit 1)
printf "\n\n"
