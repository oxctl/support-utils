#!/bin/bash
# This sets the Oxford Groups instance to be the Beta version

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

if [ -z "${host}" ] || [ -z "${token}" ] || [ -z "${get_tool_id}" ]; then 
  echo "You must set host, token and get_tool_id for this to work."
  exit 1
fi


# Check that the host is up
../check-up/check-up "https://${host}/help_links" || (echo "Not running, host isn't up"; exit 1)

printf "Setting names and labels to be 'Oxford Groups Beta' and consumer key to be 'ox' for tool with ID ${get_tool_id}\n"

# See: https://canvas.instructure.com/doc/api/external_tools.html

curl -s -X PUT "https://${host}/api/v1/accounts/1/external_tools/9604"   \
     -H "Authorization: Bearer ${token}"  \
     -F "course_navigation[text]=Oxford Groups Beta" \
     -F "course_navigation[label]=Oxford Groups Beta" \
     -F "account_navigation[text]=Oxford Groups Beta" \
     -F "account_navigation[label]=Oxford Groups Beta" \
     -F "consumer_key=ox"  \
     -F "name=Beta GET (Oxford Groups)" | jq \
     || (printf "Unable to set Oxford Groups to use the Beta version. Please do this manually.\n\n"; exit 1)

printf "\n\n"
