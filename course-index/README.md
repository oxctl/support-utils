# Manage the course index settins

These scripts are for managing the course index settings on a large number of courses

## Usage

Run a provisioning report on the courses for the account/term and then download the CSV. This file is then fed into the script and for each course it will enable/disable the public course index on the course. This will set all the courses in `course.csv` to have the public list of courses enabled on the University of Oxford test instance.

    cat courses.csv | /.manage-course-index.sh -h universityofoxford.test.instructure.com -s true

It will always output a spreadsheet containing the previous values of all the courses.

