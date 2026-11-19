# Arguments: the file to push ($FILEPATH), the redmine URL ($RM_URL) and authentication ($REDMINE_TOKEN), The project ID ($RM_PROJECT_ID) and the version ID ($RM_VERSION_ID) or issue ID ($RM_ISSUE_ID).  
# If an Issue ID is specified, then the file is attached to that issue.
# If a Version ID is specified, then the file is attached to that version in the "Files" section.
# If neither an Issue ID nor a Version ID is specified, then the file is attached to the project in the "Files" section but with no version specified.
# This script supports pushing files to Redmine using the REST API and can support files up to 2GB in size (if supported by the Redmine server configuration).

# TODO
exit 1;
