#!/bin/bash
# This adds all dev tools at the root

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

if [ -z "${host}" ] || [ -z "${token}" ] || [ -z "${client_ids}" ]; then 
  echo "You must set host, token and client_id for this to work."
  exit 1
fi

# Space sepatated list of client IDs - 1-1 correspondance with tool IDs
read -r -a client_ids_array <<< "${client_ids}"

# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)


# -----------------------------------------------------------------

# Get a list of all external tools & extract the line showing the developer_key_ids, save in a tmp file

dev_key_ids_file=$(mktemp) 
curl -s -X GET https://${host}/api/v1/accounts/1/external_tools?per_page=1000  \
    -H "Authorization: Bearer ${token}"  | jq | grep "developer_key_id" >> $dev_key_ids_file

# Add each tool where we have a client ID but only if it isnt already installed
for client_id in "${client_ids_array[@]}"
do

  # generate the developer_key_id, remove the 122010000... bit
  tmp="${client_id:5}"
  developer_key_id="$((10#$tmp))"

  #printf "\nSetting up tool with client ID of ${client_id} and developer_key_id of ${developer_key_id}\n"

  # was the tool with the corresponding dev_key in the tools list
  if grep -q -F "\"developer_key_id\": ${developer_key_id}," $dev_key_ids_file; then 

    echo "Tool with client_id ${client_id} is already installed"; 

  else

    echo "Tool with client_id ${client_id} will be installed"; 

    client_id_json_file=$(mktemp ${client_id}-XXXX)
    curl -s -X POST https://${host}/api/v1/accounts/1/external_tools  \
      -H "Authorization: Bearer ${token}" \
      -F "client_id=${client_id}" | jq > $client_id_json_file

    # was the tool set up or was there an error
    if grep -q -F "\"developer_key_id\": ${developer_key_id}," $client_id_json_file; then 
      cat $client_id_json_file | jq -r '.name' | tr '\n' ' '; 
      printf "successfully set up\n\n"; 
    else
       printf "** Unable to set tool with client ID ${client_id}. Please do this manually. **\n\n";
    fi

    # Tidy up
    rm $client_id_json_file

  fi  

done

# remove the temp file
rm $dev_key_ids_file

