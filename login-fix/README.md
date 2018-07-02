# Update of discovery page URLs

This simple shell script updates the discovery URL in Canvas. This is useful for
test/beta deployments that get refreshed from live and allows the URLs to be
reset after the refresh.

## Requirements

To run this:

* curl
* bash


## Usage

Copy `exmaple.env` to `test.env` and edit to reflect your environment. Then
schedule regular changes to have this update run through something like cron.

    update_login.sh test.env

If everything goes ok there should be no output. If there's a problem this 
should generate a error and cron should email the results.
