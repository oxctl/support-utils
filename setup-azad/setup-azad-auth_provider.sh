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


# POST /api/v1/accounts/:account_id/authentication_providers
auth_object=`curl "https://${host}/api/v1/accounts/1/authentication_providers"  -H "Authorization: Bearer ${token}" -s \
  -F "auth_type=saml"\
  -F "log_out_url=${log_out_url}"\
  -F "idp_entity_id=${idp_entity_id}"\
  -F "log_in_url=${log_in_url}"\
  -F "certificate_fingerprint=${certificate_fingerprint}" | jq`

printf "Auth object"
printf "${auth_object}" | jq

id=`echo "${auth_object}" | jq '.id'`

# TO DO
# if the above is successful, we should now change the login route to be https://${host}/login/saml/<<id-from-above-curl-response>>
printf "TO DO Set login URL to be https://${host}/login/saml/${id}\n\n"

curl -XPUT "https://${host}/api/v1/accounts/1/sso_settings' \
     -F "sso_settings[auth_discovery_url]=https://${host}/login/saml/${id}" \
     -s -H "Authorization: Bearer ${token}"
