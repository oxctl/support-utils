#!/bin/bash
#
# enable/disable the public course index
# Needs csvcut, ccurl and jq installed.

usage() { echo "Usage: $0 -h hostname [-s <true|false>]" 1>&2; exit 1; }

while getopts ":s:h:" o; do
    case "${o}" in
        s)
            setting=${OPTARG}
	    [ "$setting" == "true" ] || [ "$setting" == "false" ] || usage
            ;;
	h)
	    host=${OPTARG}
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[ -z "$host" ] && usage

# Course ID is in the first column and skip the header.
csvcut -c canvas_course_id | tail +2| while read id; do
    echo -n "$id,"
    ccurl -s https://${host}/api/v1/courses/${id}?include[]=indexed | jq '.indexed'
    if [ -n "$setting" ]; then
      ccurl -s -X PUT -Fcourse[indexed]=${setting} -o /dev/null https://${host}/api/v1/courses/${id} || echo "Failed to update ${id}" 1>&2; exit 1
    fi

done
