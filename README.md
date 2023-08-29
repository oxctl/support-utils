# canvas-support
Supporting scripts for Canvas deployments

* [add-admins](add-admins) Script to add additional admins on a Canvas deployment
* [check-up](check-up) Small script to check that the host is up and wait until it is (up to a day).
* [copy-get-rules](copy-get-rules) Script to copy the Group Enrolment Tool rules from Canvas production to Canvas Test and Canvas Beta.
* [course-index](course-index) Script to check which courses have course index enabled and also to optionally enable it.
* [last-user-access](last-user-access) Script to download the last user access report
* [login-fix](login-fix) Script to update the discovery page on a Canvas deployment
* [requeue](requeue) Small script to run the passed command and if the command fails schedule it to be re-run with at(1).
* [tabs-enabled](tabs-enabled) Small script to check which courses have the Chat tab enabled.
* [set-GET-beta](set-GET-beta) Small script to setthe version of GET to be the Beta version.
* [setup-azad-auth](setup-azad-auth) Sets up AzAD auth provider, sets discovery page to this new auth route & deletes the auth provider copied from prod each. But not in that order!
