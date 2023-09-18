#!/bin/bash
# This adds all dev tools at the root

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

if [ -z "${host}" ] || [ -z "${token}" ] || [ -z "${client_ids}" ]; then 
  echo "You must set host, token and client_id for this to work."
  exit 1
fi

# Space sepatated list of client IDs - 1-1 correspondance with tool IDs
read -r -a client_ids_array <<< "${client_ids}"

# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)

# Add each tool where we have a client ID
for client_id in "${client_ids_array[@]}"
do
  printf "\nSetting up tool with client ID of ${client_id}: "
  curl -X POST https://${host}/api/v1/accounts/1/external_tools  \
    -H "Authorization: Bearer ${token}" \
    -F "client_id=${client_id}" | jq -r '.name' | tr '\n' ' '; \
    printf "successfully set up\n\n" \
    || printf "Unable to set tool with client ID ${client_id}. Please do this manually.\n\n"
    printf "\n\n"
done

