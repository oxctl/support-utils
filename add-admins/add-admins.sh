#!/bin/bash
# This adds additional admins to a canvas deployment

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

if [ -z "${host}" ] || [ -z "${token}" ] || [ -z "${admins}" ]; then 
  echo "You must set host, token and admins for this to work."
  exit 1
fi

# Check that the host is up
../check-up/check-up "https://${host}/health_check" || (echo "Not running, host isn't up"; exit 1)

# Space sepatated list of user IDs
read -r -a admin_array <<< "${admins}"

for admin in "${admin_array[@]}"
do
  curl -X POST -f \
    -o /dev/null -s \
    https://$host/api/v1/accounts/1/admins \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $token" \
    -H 'Cache-Control: no-cache' \
    -F "user_id=$admin"

  code=$?
  if [ $code -ne 0 ]; then
    if [ $code -eq 22 ]; then
      cat notice.txt
      echo "Login failed for: ${host}\nCheck token is valid"
    else
      cat notice.txt
      echo "Failed to add: $admin for: $host"
    fi
    exit 1
  fi
done

