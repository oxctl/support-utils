# Switch GET tool registration to point at the Beta version which is qhat is required for Canvas Test and Beta - DO NOT USE ON PRODUCTION

This simple shell script will make Canvas use the Beta version of the Oxford Groups tool. It:

* swaps the consumer key from 'oxford' to 'ox'
* changes the course and account navigation text and labels to be 'Oxford Groups Beta'
* changes the tool name to be 'Oxford Groups Beta'

## Requirements

To run this:

* curl
* bash
* jq


## Usage

Copy `exmaple.env` to `beta.env` (or `test.env`) and edit to reflect your environment. Then
schedule regular runs just AFTER test / beta refresh using something like cron. For example, 

    set-GET-beta.sh beta.env

If everything goes ok then the output of the script is a JSON object detailing the tool configuration
