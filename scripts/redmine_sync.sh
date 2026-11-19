#!/bin/bash
set -euo pipefail

### This is a bash script which supports pushing data to and from Redmine from github actions.
###  - This script is designed to be run on every trigger supported by github actions and be a no-op if the trigger is not supported.
###     - This allows for a single script to be used in multiple workflows, and for workflows to be triggered by multiple events.
###     - This also allows this script to add more functionality in the future without having to modify existing workflows.
### It supports the following commands:
###  - link: Links the specified GitHub Pull Request to the specified Redmine issue. (calls link_to_redmine.sh)
###     - Should support everything in workflows/link-to-redmine.yml
###     - Should support everything in workflows/add-to-redmine.yml
###     - Should support everything in workflows/auto-add-to-pr-and-redmine.yml *except* for what's in workflows/auto-add-pr.yml (which will be run separately)
###  - sync: Updates the previously linked Redmine issue with the latest information from the GitHub Pull Request. (calls sync_to_redmine.sh)
###     - Should support everything in workflows/edit-redmine.yml and workflows/update-redmine.yml
###  - wiki: Updates the specified Redmine Wiki page with the specified content. (calls update_wiki.sh)
###  - file: Uploads the specified file to the specified Redmine project. (calls push_file.sh)

echo "Starting Redmine synchronization..."

echo "You passed the arguments: "
echo "$@"

# TODO
exit -1
