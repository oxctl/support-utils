# Update of deployment admins

This simple shell script updates the account admins. This is useful for 
test/beta deployments that get refreshed from live and allows the more people
to have admin rights for development/testing without risking the live service.
Adding admins works even if they are already an admin so it's fine to run
this script repeatedly. You can have multiple roles in a (sub)account so
after this script's run users may appear with multiple admin entries.

## Requirements

To run this:

* curl
* bash


## Usage

Copy `exmaple.env` to `test.env` and edit to reflect your environment. Then
schedule regular changes to have this update run through something like cron.

    add_admins.sh test.env

If everything goes ok there should be no output. If there's a problem this 
should generate a error and cron should email the results.
