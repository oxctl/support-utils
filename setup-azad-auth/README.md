# Set Up Azure Active Directory Authentication Provider - DO NOT USE ON PRODUCTION

This simple shell script sets up AzAD by:

* deletes the prod AzAD auth provider as this stops AzAD from working
* creates AzAD auth provider
* sets the Discovery page to be the newly set up AzAD login page

## Requirements

To run this:

* curl
* bash
* jq


## Usage

Copy `exmaple.env` to `beta.env` (or `test.env`) and edit to reflect your environment. Then
schedule regular runs just AFTER test / beta refresh using something like cron.

    setup-azad-auth.sh beta.env

If everything goes ok the the output of the script is a set of 3 JSON objects each detailing the success or failure of the three steps
