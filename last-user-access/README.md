# Download Last User Access report

This simple shell script downloads the Last User Access report. It is useful
for seeing who has accessed test/beta deployments and is typically run just 
before they get refreshed from live (which results in all access logs being overwritten).

## Requirements

To run this:

* curl
* bash
* jq
* sed
* head
* csvsort - part of csvkit
* csvcut - part of csvkit

## Usage

Copy `example.env` to `beta.env` (or `test.env`) and edit to reflect your environment. Then
schedule regular runs just before test / beta refresh using something like cron.

    last-user-access.sh beta.env

If everything goes ok the the output of the script is the report: a CSV file which 'cron' should email.
If there's a problem this should generate a error and 'cron' should email the results.
