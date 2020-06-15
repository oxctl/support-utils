#!/bin/bash
#
# Takes a users.csv file and generates an enrollments.csv for a course
#

csvcut -c user_id | awk '
  BEGIN {
    OFS="\t"
    print "user_id", "course_id", "role", "status"
  }
  NR > 1 {
    print $1, "course-1", "student", "active"
  }
' | csvformat -t
