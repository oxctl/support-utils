# Set up specific discovery page on none production environments - DO NOT USE ON PRODUCTION

The AzAD auth routes are set up on Production Canvas and are copied as part of the regular refresh process

This simple shell script sets up AzAD by:

* deletes the prod AzAD auth provider as this stops AzAD from working
* sets the Discovery page to be the environment's pre-configured AzAD login page

At the time of writing, Test uses the same as production /login/saml

## Requirements

To run this:

* curl
* bash
* jq


## Usage

Copy `example.env` to `beta.env` (or `test.env`) and edit to reflect your environment. Then
schedule regular runs just AFTER test / beta refresh using something like cron. For example, 

    set-discovery-page.sh beta.env

If everything goes ok the the output of the script is a JSON object detailing the success or failure of the script
