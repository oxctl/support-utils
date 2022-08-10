#!/bin/bash
# This downloads the last user access report from Canvas

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

id=`curl -X POST  https://${host}/api/v1/accounts/1/reports/last_user_access_csv  -s -H "Authorization: Bearer ${token}" | jq '.id'`

# wait 
sleep 300

loop_counter=0
while [ true ]
do 

	if [ ${loop_counter} -gt 20 ]
	then
		echo "Too many failed attempts (${loop_counter}) to retrieve the report, quitting"
		exit 1
	fi

	# increment counter
	loop_counter=$((loop_counter+1))

	# fetch response, check if report complete
	check_report_json=`curl -X GET https://${host}/api/v1/accounts/1/reports/last_user_access_csv/${id}  -s -H "Authorization: Bearer ${token}" `

	# grab value of status in JSON
	status=`echo ${check_report_json} | jq '.status'`

	# does the result include a status of 'complete'? 
	if [ -z ${status} ]
	then
		sleep 300
	else
		if [ ${status} = "\"complete\"" ]
		then

			# echo "Report is complete"
	
			# grab the report's URL & remove quotes
			url=`echo ${check_report_json} | jq -r '.attachment.url'`

			#DEBUG echo "URL of report is ${url} Fetching ............}"

			# grab the report, put last accessed column first, delete all lines where no login, sort on first column and write out first 100 lines
			curl  -L -X GET ${url} -s -H "Authorization: Bearer ${token}" | csvcut -c 4,1,2,3,5 | sed -e '/^,/d'| csvsort -r -c 1 | head -100
			exit 0
		else
			sleep 300
		fi
	fi
done

