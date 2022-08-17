#!/bin/bash
# This create an AzAD authentication provider in Canvas 
# typically this is used for Canvas Beta which will have a URL of /login/saml/139 but could be used on any server 

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

if [ -z "${host}" ] || [ -z "${token}" ] ; then 
  echo "You must set host and token for this to work."
  exit 1
fi


# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)

set -e

# Delete prod provider (id is in env file)
printf "Attempting to delete auth provider with id = ${prod_id}\n"

# see: https://canvas.instructure.com/doc/api/authentication_providers.html#method.authentication_providers.destroy
deleted_auth_provider=`curl -XDELETE "https://${host}/api/v1/accounts/1/authentication_providers/${prod_id}" \
     -s -H "Authorization: Bearer ${token}" | jq` || printf "Unable to delete auth provider (${prod_id}) - requires manual attention\n\n"

# if the JSON include the prod_id that we've just deleted then it worked, otherwise we failed
printf "If the JSON below is an error message then we failed\n"
echo ${deleted_auth_provider} | jq
printf "\n"


# did it succeed? if response is an errior then dsisplay the reason

# Add new AzAD provider
printf "Setup AzAD auth provider\n"

# See: https://canvas.instructure.com/doc/api/authentication_providers.html#method.authentication_providers.create
auth_object=`curl "https://${host}/api/v1/accounts/1/authentication_providers" -s -H "Authorization: Bearer ${token}" \
  -F "auth_type=saml"\
  -F "log_out_url=${log_out_url}"\
  -F "idp_entity_id=${idp_entity_id}"\
  -F "log_in_url=${log_in_url}"\
  -F "certificate_fingerprint=${certificate_fingerprint}" | jq` || (printf "Unable to add AzAD auth method\n\n"; exit 1)

printf "Auth object"
printf "${auth_object}" | jq
printf "\n"

azad_id=`echo "${auth_object}" | jq '.id'`

# if the above is successful, we should now change the login route to be https://${host}/login/saml/<<azad_id-from-above-curl-response>>
printf "Setting 'discovery URL' to be https://${host}/login/saml/${azad_id}\n"

# See: https://canvas.instructure.com/doc/api/authentication_providers.html#method.authentication_providers.update_sso_settings
curl -XPUT "https://${host}/api/v1/accounts/1/sso_settings" -s -H "Authorization: Bearer ${token}"  \
     -F "sso_settings[auth_discovery_url]=https://${host}/login/saml/${azad_id}" | jq || (printf "Unable to set Discovery URL\n\n"; exit 1)
printf "\n\n"
