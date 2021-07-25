#!/bin/bash
#
# Copies get rules from prod to test and beta
# Needs cut, ccurl, iconv installed.

if [ "$1" == "" ]; then
  echo Usage: $(basename $0) live_token beta_token test_token;
  exit 1;
fi

live_token="$1";
beta_token="$2";
test_token="$3";

if [ -z "${live_token}" ] || [ -z "${beta_token}" ] || [ -z "${test_token}" ]; then
  echo "You must set live_token, beta_token and test_token for this to work."
  exit 1
fi

# Send start email
echo "Subject: ***Copy GET rules process***: Starting process to copy GET rules from production to test and beta" | sendmail nick.wilson@it.ox.ac.uk;

echo "Live token is" $live_token;
echo "beta token is"  $beta_token;
echo "Test token is" $test_token;

# Export GET rules from production
echo "Exporting the GET rules from production\n";
job_id=$(curl --location --request POST 'https://canvas-group-enrollment-dub-prod.insproserv.net/export/rules' --header 'Authorization: '$live_token  | grep -Po 'job_id":\K[0-9]+' )
statusUrl=https://canvas-group-enrollment-dub-prod.insproserv.net/status/$job_id;
echo "Job id is" $job_id;

# Test for job id
if [ -z "$job_id" ]  ; then
    echo "Job id empty so exiting....";
    exit 1;
fi

# Check to see if the rules export has finished
zipSaved=$( date '+%F_%H_%M_%S_exported.zip' );
zipCopySaved=$( date '+%F_%H_%M_%S_exported_copy.zip' );
folderToSave=$( date '+%F_%H_%M_%S' );
runtime="5 minute"
endtime=$(date -ud "$runtime" +%s)
while [[ $(date -u +%s) -le $endtime ]]
do
	echo "Job id is" $job_id;
	echo "Time Now: `date +%H:%M:%S`"
    	echo "Sleeping for 30 seconds\n"
    	sleep 30
    	status=$(curl --location --request GET $statusUrl --header 'Authorization: '$live_token  | sed -n 's|.*"status":"\([^"]*\)".*|\1|p' )
	if [ $status == "completed" ]; 	then
		echo "Success! Export completed";
		exportCompleted=true;
		break;
    fi

    if [ $status == "failed" ]; 	then
   		echo "Failure! Export failed";
    	exit 1;
    fi
   echo "Not processed yet - trying again in 30 seconds..."
done

#   Exit if export not complete
if [ "$exportCompleted" != true ] ; then
	echo "Export not complete within 5 minutes so exiting with failure...\n"
	exit 1;
fi

# Import the rules onto Canvas Test and Beta
if [ "$exportCompleted" = true ] ; then

    echo "Export complete within 5 minutes so processing file...\n"

	# Get the rules export zip
    file_processed=$(curl --location --request GET $statusUrl --header 'Authorization: '$live_token | sed -n 's|.*"file_processed":"\([^"]*\)".*|\1|p' );
	mkdir ./$folderToSave;
	wget $file_processed -O ./$folderToSave/$zipSaved;
    cd ./$folderToSave;
	cp $zipSaved $zipCopySaved;
	unzip $zipCopySaved;

	# Removing rule_id and user_group_id columns
	echo "Removing rule_id and user_group_id columns from 3 files...";
	cut -d, -f2 --complement rules.csv > rules1.csv;
	cut -d, -f2 --complement rule_groups.csv > rule_groups1.csv;
	cut -d, -f2 --complement rule_groups1.csv > rule_groups2.csv;
	cut -d, -f2 --complement rule_courses.csv > rule_courses1.csv;

	# This section is for testing changes
	#head -n 2 "rules1.csv" >"rules.csv";
	#head -n 2 "rule_groups1.csv" >"rule_groups.csv";
	#head -n 2 "rule_courses1.csv" >"rule_courses.csv";

	# Rename column
	sed -i '1s/rule_id/rule_import_id/'  rules1.csv;
	sed -i '1s/rule_id/rule_import_id/' rule_groups2.csv;
	sed -i '1s/rule_id/rule_import_id/' rule_courses1.csv;

	# Convert to utf8
	iconv -c -f utf-8 -t ascii  rules1.csv -o rules2.csv;
	iconv -c -f utf-8 -t ascii  rule_groups2.csv -o rule_groups3.csv;
	iconv -c -f utf-8 -t ascii  rule_courses1.csv -o rule_courses2.csv;

	# Zipping files to import
	zipToImport=$( date '+%F_%H_%M_%S_to_import.zip' );
	zip -r $zipToImport rules2.csv rule_groups3.csv rule_courses2.csv;

	# Importing rules to test...
	echo "Importing rules to test...";
	import_job_id=$(curl --location --request POST 'https://canvas-group-enrollment-dub-test.insproserv.net/import/rules' \
	--header 'Authorization: '$test_token --form 'file=@'$zipToImport | grep -Po 'job_id":\K[0-9]+' );
	statusImportUrl=https://canvas-group-enrollment-dub-test.insproserv.net/status/$import_job_id;

	# Test for job id
    if [ -z "import_job_id" ]  ; then
        echo "Job id empty so exiting....";
        exit 1;
    fi

	# Check if import has finished
	echo "import job id: " $import_job_id;
	runtime="60 minute"
	endtime=$(date -ud "$runtime" +%s)
	while [[ $(date -u +%s) -le $endtime ]]
	do
		echo "Job id is" $import_job_id;
		echo "Time Now: `date +%H:%M:%S`"
    		echo "Sleeping for 30 seconds"
    		sleep 30
    		importStatus=$(curl --location --request GET $statusImportUrl --header 'Authorization: '$test_token | sed -n 's|.*"status":"\([^"]*\)".*|\1|p' )
		if [ $importStatus == "completed" ]; 	then
			echo "Success! Import to test completed";
			importCompleted=true;
			break;
    		fi

		if [ $importStatus == "failed" ]; 	then
			echo "Failure! Import to test not fully completed";
			break;
    		fi
   		echo "Import to test not processed yet - trying again in 30 seconds..."
	done

	# Exit if import to test not complete within 60 mins
	if [ "$importCompleted" != true ] ; then
		echo "Import to test not complete within 60 minutes so exiting with failure...";
		echo "Subject: ***Copy GET rules process***: Failed to imported rules to Canvas Test" | sendmail nick.wilson@it.ox.ac.uk;
		exit 1;
	fi

	# Send success email
	if [ "$importCompleted" = true ] ; then
		echo "Import to test complete within 60 minutes";
		echo "Subject: ***Copy GET rules process***: Imported rules to Canvas Test" | sendmail nick.wilson@it.ox.ac.uk;
	fi

	# Importing rules to beta...
	echo "Importing rules to beta...";
	import_job_id_beta=$(curl --location --request POST 'https://canvas-group-enrollment-dub-test.insproserv.net/import/rules' --header 'Authorization: '$beta_token --form 'file=@'$zipToImport | grep -Po 'job_id":\K[0-9]+' );
	statusImportUrl=https://canvas-group-enrollment-dub-test.insproserv.net/status/$import_job_id_beta;

	# Test for job id
    if [ -z "import_job_id" ]  ; then
        echo "Job id empty so exiting....";
        exit 1;
    fi

	# Check if import to beta has finished
	echo "import job id beta: " $import_job_id_beta;
	runtime="60 minute"
	endtime=$(date -ud "$runtime" +%s)
	while [[ $(date -u +%s) -le $endtime ]]
	do
		echo "Job id is" $import_job_id_beta;
		echo "Time Now: `date +%H:%M:%S`"
    		echo "Sleeping for 30 seconds"
    		sleep 30
    		importStatus=$(curl --location --request GET $statusImportUrl --header 'Authorization: '$beta_token | sed -n 's|.*"status":"\([^"]*\)".*|\1|p')
		if [ $importStatus == "completed" ]; 	then
			echo "Success! Import to beta completed";
			importCompleted=true;
			break;
    		fi

		if [ $importStatus == "failed" ]; 	then
			echo "Failure! Import to beta not fully completed";
			break;
    		fi
   		echo "Import to beta not processed yet - trying again in 30 seconds..."
	done

	# Exit if import not complete
	if [ "$importCompleted" != true ] ; then
		echo "Import to beta not complete within 60 minutes so exiting with failure...";
		echo "Subject: ***Copy GET rules process***: Failed to imported rules to Canvas Beta" | sendmail nick.wilson@it.ox.ac.uk;
		exit 1;
	fi

	# Send success email
	if [ "$importCompleted" = true ] ; then
		echo "Import to beta complete within 60 minutes";
		echo "Subject: ***Copy GET rules process***: Imported rules to Canvas Beta" | sendmail nick.wilson@it.ox.ac.uk;
	fi
fi

echo "Finished imports successfully";
# Sending starting email
echo "Subject: ***Copy GET rules process***: Finished process successfully to copy GET rules from production to test and beta" | sendmail nick.wilson@it.ox.ac.uk;
