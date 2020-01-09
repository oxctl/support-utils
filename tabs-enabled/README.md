# Check how many tabs are enabled

This script will check all the courses in the CSV that is passed to it and for each one output if the chat tool is enabled in it.

## Usage

Run a provisioning report on the courses for the account/term and then download the CSV. This file is then fed into the script and for each course it will check to see if the Chat tool is enabled. If you want to check a different tool just find the ID of it and update the script.

    cat courses.csv | check-tabs.sh | tee output.csv

This will output a CSV. If the tool is enabled then it will be visible to "members", if it's been disabled then it will only be visible to "admins".

