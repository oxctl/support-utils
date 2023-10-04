# Adds all 'dev' versions of LTI 1.3 tools at the root sub-account on Canvas Beta (and Test) if they arent already deployed - DO NOT USE ON PRODUCTION

This simple shell script will make Canvas use the DEV versions of all LTI 1.3 tools. It:

* builds a list of already installed tools (keyed on 'developer_key_id')
* ensures these one copy of each tool whose 'client_id' is given as an array element in the "env" file at the root sub-account
* assumes the dev version of the tool has already been already set up but not deployed

## Requirements

To run this:

* curl
* mktemp
* bash
* grep
* jq


## Usage

Copy `exmaple.env` to `beta.env` (or `test.env`) and edit to reflect your environment. Then
schedule regular runs just AFTER test / beta refresh using something like cron. For example, 

    add-LTI-dev.sh beta.env

If everything goes ok then the output of the script is a list of success messages, one per tool
