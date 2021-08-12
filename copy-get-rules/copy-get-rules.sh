#!/bin/bash
#
# Copies get rules from prod to test and beta
# Needs cut, ccurl, iconv installed.

if [ "$1" == "" ]; then
  echo Usage: $(basename $0) live_token beta_token test_token enviroment;
  exit 1;
fi

live_token="$1";
beta_token="$2";
test_token="$3";
env="$4";

if [ -z "${live_token}" ] || [ -z "${beta_token}" ] || [ -z "${test_token}" ] || [ -z "${env}" ]; then
  echo "You must set live_token, beta_token and test_token and the environment for this to work."
  exit 1
fi

if [ "$env" = 'prod' ]  ; then
		# Send start email
        echo "Subject: ***Copy GET rules process*** ($env version): Starting process to copy GET rules from production to test and beta" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
else
        echo "Subject: ***Copy GET rules process*** ($env version): Starting process to copy GET rules from production to $env" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
fi


echo "Live token is" $live_token;
echo "beta token is"  $beta_token;
echo "Test token is" $test_token;

# Export GET rules from production
echo "Exporting the GET rules from production\n";
job_id=$(curl --location --request POST 'https://canvas-group-enrollment-dub-prod.insproserv.net/export/rules' --header 'Authorization: '$live_token  | jq -r '.job_id' )
statusUrl=https://canvas-group-enrollment-dub-prod.insproserv.net/status/$job_id;

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
    	status=$(curl --location --request GET $statusUrl --header 'Authorization: '$live_token  | jq -r '.status' )
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
    echo "Subject: ***Copy GET rules process*** ($env version): Export complete within 5 minutes so processing zip file..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;


	# Get the rules export zip
    file_processed=$(curl --location --request GET $statusUrl --header 'Authorization: '$live_token | jq -r '.details.file_processed' );
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

	# If test or beta, cut down files if test or beta
	if [ "$env" = 'test' ] || [ "$env" = 'beta' ]  ; then
		echo "Subject: ***Copy GET rules process*** ($env version): Cutting files down" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;

		# This section is for testing changes
		head -n 2 "rules1.csv" >"rules_test.csv";
		head -n 2 "rule_groups2.csv" >"rule_groups_test.csv";
		head -n 2 "rule_courses1.csv" >"rule_courses_test.csv";

		mv rules_test.csv rules1.csv;
		mv rule_groups_test.csv rule_groups2.csv;
		mv rule_courses_test.csv rule_courses1.csv;
	fi

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
	if [ "$env" = 'test' ] || [ "$env" = 'prod' ]  ; then
        echo "Importing rules to test...";
        echo "Subject: ***Copy GET rules process*** ($env version): Importing rules to test..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		import_job_id=$(curl --location --request POST 'https://canvas-group-enrollment-dub-test.insproserv.net/import/rules' \
		--header 'Authorization: '$test_token --form 'file=@'$zipToImport | jq -r '.job_id' );
		statusImportUrl=https://canvas-group-enrollment-dub-test.insproserv.net/status/$import_job_id;

		# Test for job id
		    if [ -z "import_job_id" ]  ; then
			echo "Job id empty so exiting....";
			exit 1;
		    fi

		# Check if import has finished
		echo "import job id: " $import_job_id;
		runtime="1080 minute"
		endtime=$(date -ud "$runtime" +%s)
		while [[ $(date -u +%s) -le $endtime ]]
		do
			echo "Job id is" $import_job_id;
			echo "Time Now: `date +%H:%M:%S`"
	    		echo "Sleeping for 30 seconds"
	    		sleep 30
	    		importStatus=$(curl --location --request GET $statusImportUrl --header 'Authorization: '$test_token | jq -r '.status' )
			if [ $importStatus == "completed" ]; 	then
				echo "Success! Import to test completed";
				importCompleted=true;
				break;
	    	fi

			if [ $importStatus == "failed" ]; 	then
				echo "Failure! Import to test not fully completed";
		        echo "Subject: ***Copy GET rules process*** ($env version): Failure! Import to test returned with 'failed' status" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
				break;
	    		fi
	   		echo "Import to test not processed yet - trying again in 30 seconds..."
		done

		# Exit if import to test not complete within 9 hours mins
		if [ "$importCompleted" != true ] ; then
			echo "Import to test not complete within 9 hours so exiting with failure...";
			echo "Subject: ***Copy GET rules process*** ($env version): Failed to imported rules to Canvas Test within 9 hours" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
			exit 1;
		fi

		# Send success email
		if [ "$importCompleted" = true ] ; then
			echo "Import to test complete within 9 hours";
			echo "Subject: ***Copy GET rules process*** ($env version): Imported rules to Canvas Test successfully" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		fi
    	fi



	
	# Importing rules to beta...
	if [ "$env" = 'beta' ] || [ "$env" = 'prod' ]  ; then


		# Importing rules to beta...
		echo "Importing rules to beta...";
        echo "Subject: ***Copy GET rules process*** ($env version): Importing rules to beta..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		import_job_id_beta=$(curl --location --request POST 'https://canvas-group-enrollment-dub-test.insproserv.net/import/rules' --header 'Authorization: '$beta_token --form 'file=@'$zipToImport | jq -r '.job_id' );
		statusImportUrl=https://canvas-group-enrollment-dub-test.insproserv.net/status/$import_job_id_beta;

		# Test for job id
	    if [ -z "import_job_id" ]  ; then
		echo "Job id empty so exiting....";
		exit 1;
	    fi

		# Check if import to beta has finished
		echo "import job id beta: " $import_job_id_beta;
		runtime="120 minute"
		endtime=$(date -ud "$runtime" +%s)
		while [[ $(date -u +%s) -le $endtime ]]
		do
			echo "Job id is" $import_job_id_beta;
			echo "Time Now: `date +%H:%M:%S`"
	    		echo "Sleeping for 30 seconds"
	    		sleep 30
	    		importStatus=$(curl --location --request GET $statusImportUrl --header 'Authorization: '$beta_token | jq -r '.status' )
			if [ $importStatus == "completed" ]; 	then
				echo "Success! Import to beta completed";
				importCompleted=true;
				break;
	    		fi

			if [ $importStatus == "failed" ]; 	then
				echo "Failure! Importing rules to Canvas Beta returned with 'failed' status";
				break;
	    		fi
	   		echo "Import to beta not processed yet - trying again in 30 seconds..."
		done

		# Exit if import not complete
		if [ "$importCompleted" != true ] ; then
			echo "Import to beta not complete within 60 minutes so exiting with failure...";
			echo "Subject: ***Copy GET rules process*** ($env version): Failed to imported rules to Canvas Beta within 120 minutes " | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
			exit 1;
		fi

		# Send success email
		if [ "$importCompleted" = true ] ; then
			echo "Import to beta complete within 60 minutes";
			echo "Subject: ***Copy GET rules process*** ($env version): Imported rules to Canvas Beta successfully" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		fi
	fi
fi

echo "Finished imports successfully";


if [ "$env" = 'prod' ]  ; then
		# Send start email
        echo "Subject: ***Copy GET rules process*** ($env version): Finished process to copy GET rules from production to test and beta" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
else
        echo "Subject: ***Copy GET rules process*** ($env version): Finished process to copy GET rules from production to $env" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
fi
