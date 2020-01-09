#!/bin/bash
#
# Check how many courses have the Chat tool enabled
# Needs csvcut, ccurl and jq installed.

# Course ID is in the first column and skip the header.
csvcut -K 1 -c 1 | while read id; do
    echo -n "$id,"
    ccurl -s https://canvas.ox.ac.uk/api/v1/courses/${id}/tabs | jq '.[] | select(.id == "context_external_tool_22") | .visibility';
done
