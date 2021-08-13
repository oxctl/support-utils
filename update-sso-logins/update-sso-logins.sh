#!/bin/bash
#
# Updates SSO users' logins to their correct SSO logins
# Needs curl and awk installed.

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

if [ -z "${host}" ] || [ -z "${token}" ]; then
  echo "You must set host and token for this to work."
  exit 1
fi

# Check props
echo "token is" $token;
echo "host is"  $host;

#Send start email
echo "Subject: ***Update SSO Login Ids process*** ($host version): Starting process to update incorrect SSO logins to the correct ones on $host" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;


# Get users report
echo "Downloading users report";
echo "Subject: ***Update SSO Login Ids process*** ($host version): Downloading users report" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
job_id=$(curl --location --request POST  $host'/api/v1/accounts/1/reports/provisioning_csv' -H 'Authorization: Bearer '$token -H 'Content-Type: multipart/form-data' -F 'parameters[users]=true'  | jq -r '.id');
echo "Report job id is " $job_id;
echo "Subject: ***Update SSO Login Ids process*** ($host version): Report job id is: $job_id" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;

# Test for job id
if [ -z "$job_id" ]  ; then
    echo "Report job id empty so exiting....";
    echo "Subject: ***Update SSO Login Ids process*** ($host version): Report job id empty so exiting...." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
    exit 1;
fi

# Check to see if the rules export has finished
csvOriginalDownloaded=$( date '+%F_%H_%M_%S_original_report.csv' );
csvCopy=$( date '+%F_%H_%M_%S_report_copy1.csv' );
csvCopyOnlyOxIntIds=$( date '+%F_%H_%M_%S_report_copy_only_ox_intids.csv' );
csvCopyOnlyOxIntegrationIdAndNoOXACUK=$( date '+%F_%H_%M_%S_report_only_ox_intids_no_oxacuk.csv' );
csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseids=$( date '+%F_%H_%M_%S_report_only_ox_intids_no_oxacuk_no_ampersand.csv' );
csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsUpdate=$( date '+%F_%H_%M_%S_report_only_ox_intids_no_oxacuk_no_amp_update.csv' );
csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoAppl=$( date '+%F_%H_%M_%S_report_only_ox_intids_no_oxacuk_no_amp_update_noappl.csv' );
csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoApplNoBlanks=$( date '+%F_%H_%M_%S_report_only_ox_intids_no_oxacuk_no_amp_update_noapplblanks.csv' );
folderToSave=$( date '+%F_%H_%M_%S' );
runtime="20 minute"
endtime=$(date -ud "$runtime" +%s)
while [[ $(date -u +%s) -le $endtime ]]
do
	echo "Job id is" $job_id;
	echo "Time Now: `date +%H:%M:%S`"
    	echo "Sleeping for 30 seconds\n"
    	sleep 30
    	status=$(curl -H 'Authorization: Bearer '$token $host'/api/v1/accounts/1/reports/provisioning_csv/'$job_id | jq -r '.status' );
    	echo $status;
	if [ $status == "complete" ]; 	then
		echo "Success! Report complete";
		reportCompleted=true;
		fileUrl=$(curl -H 'Authorization: Bearer '$token $host'/api/v1/accounts/1/reports/provisioning_csv/'$job_id | jq -r '.attachment.url' );
		 echo "Success! File url: " $fileUrl;
		 echo "Subject: ***Update SSO Login Ids process*** ($host version): Success! File url: " $fileUrl | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		break;
    fi
    if [ $status == "failed" ]; 	then
   		echo "Failure! Report failed";
   	    echo "Subject: ***Update SSO Login Ids process*** ($host version): Failure! Report failed...." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
    	exit 1;
    fi
   echo "Not processed yet - trying again in 30 seconds..."
done


#   Exit if report not complete
if [ "$reportCompleted" != true ] ; then
	echo "Export not complete within 20 minutes so exiting with failure...\n";
	echo "Subject: ***Update SSO Login Ids process*** ($host version): Export not complete within 20 minutes so exiting with failure." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
	exit 1;
fi


# Format users report and upload via SIS import
if [ "$reportCompleted" = true ] ; then

    echo "Report complete within 20 minutes so processing file...\n"
    echo "Subject: ***Update SSO Login Ids process*** ($host version): report complete within 20 minutes so processing file..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;

    # Format file
	mkdir ./$folderToSave;
	cd ./$folderToSave;
	wget $fileUrl -O $csvOriginalDownloaded;
	cp $csvOriginalDownloaded $csvCopy;

	# Removing rule_id and user_group_id columns
	echo "Removing non OX- integration ids, @ox.ac.uk login ids, blank user_ids or with @ or APPL in them";
	echo "Subject: ***Update SSO Login Ids process*** ($host version): Removing non OX- integration ids, @ox.ac.uk login ids, blank user_ids or with @ or APPL in them" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
	awk -F "," '$3 ~ /^OX-|integration_id/' $csvCopy > $csvCopyOnlyOxIntIds;
	awk -F "," '$5 !~ /@ox.ac.uk/' $csvCopyOnlyOxIntIds > $csvCopyOnlyOxIntegrationIdAndNoOXACUK;
	awk -F "," '$2 !~ /@/' $csvCopyOnlyOxIntegrationIdAndNoOXACUK > $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseids;
	awk -F "," '$2 !~ /^APPL/' $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseids > $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoAppl;
	awk -F "," '$2 != "" ' $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoAppl > $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoApplNoBlanks;
	awk -F ',' -v OFS=',' '$1 { if ($5!="login_id" && $2!="") $5=$2"@ox.ac.uk"; print}'  $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsNoApplNoBlanks > $csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsUpdate;


    	# Importing formatted users to env...
        echo "SIS Importing users with correct logins to $host...";
        echo "Subject: ***Update SSO Login Ids process*** ($host version): SIS Importing users with correct logins to $host..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		import_job_id=$(curl -F 'attachment=@'$csvCopyOnlyOxIntegrationIdAndNoOXACUKAndNoAmpersandInUseidsUpdate -H 'Authorization: Bearer '$token $host'/api/v1/accounts/1/sis_imports.json?import_type=instructure_csv' | jq -r '.id');


		echo "Sis import done .Id is" $import_job_id;
		echo "Subject: ***Update SSO Login Ids process*** ($host version):Sis import done. Id is" $import_job_id | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		statusImportUrl=$host'/api/v1/accounts/1/sis_imports/'$import_job_id;

		# Test for job id
		if [ -z "import_job_id" ]  ; then
			echo "Sis import Job id empty so exiting....";
			echo "Subject: ***Update SSO Login Ids process*** ($host version): Sis import Job id empty so exiting...." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
			exit 1;
		fi

		# Check if import has finished
		runtime="60 minute"
		endtime=$(date -ud "$runtime" +%s)
		while [[ $(date -u +%s) -le $endtime ]]
		do
			echo "Job id is" $import_job_id;
			echo "Time Now: `date +%H:%M:%S`"
	    		echo "Sleeping for 30 seconds"
	    		sleep 30
	    		importStatus=$(curl --location --request GET $statusImportUrl -H 'Authorization: Bearer '$token | jq -r '.workflow_state' )
			if [[ "$importStatus" == *"imported"* ]]; then
				echo "Success! SIS Import to $env completed";
				echo "Subject: ***Update SSO Login Ids process*** ($host version):Success! SIS Import to $env completed" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
				importCompleted=true;
				break;
	    	fi

			if [[ "$importStatus" == *"failed"* ]]; then
				echo "Failure! Import to $host failed";
		        echo "Subject: ***Update SSO Login Ids process*** ($host version): Failure! Import to $host failed" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
				break;
	    	fi
	   		echo "SIS Import not processed yet - trying again in 30 seconds..."
		done

		# Exit if import to test not complete within 60 mins
		if [ "$importCompleted" != true ] ; then
			echo "SIS Import not complete within 60 minutes so exiting with failure...";
			echo "Subject: ***Update SSO Login Ids process*** ($host version): SIS Import not complete within 60 minutes so exiting with failure..." | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
			exit 1;
		fi

		# Send success email
		if [ "$importCompleted" = true ] ; then
			echo "SIS Import complete within 60 minutes";
			echo "Subject: ***Update SSO Login Ids process*** ($host version): SIS Import complete within 60 minutes" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;
		fi
fi

echo "Finished imports successfully";
echo "Subject: ***Update SSO Login Ids process*** ($host version): Finished process to update incorrect SSO logins to the correct ones on $host" | /usr/sbin/sendmail nick.wilson@it.ox.ac.uk;