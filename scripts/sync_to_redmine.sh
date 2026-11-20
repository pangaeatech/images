#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${RM_LIB_DIR:-$HERE/lib}"
# shellcheck source=lib/common.sh
. "$LIB/common.sh"
# shellcheck source=lib/platform.sh
. "$LIB/platform.sh"

# Pushes PR/MR changes to every Redmine issue linked to it.
# Usage: sync_to_redmine.sh edit   # update subject + description
#        sync_to_redmine.sh note   # add a note from a review/comment (CMT_* vars)
#
# Env: RM_URL REDMINE_TOKEN RM_PROJECT_ID RM_FIELD_ID [RM_SUFFIX] [DRAFT_PREFIX], plus PR_*/CMT_*

mode="${1:-}"
rm_init
load_context
require_vars RM_PROJECT_ID RM_FIELD_ID PR_NUM

case "$mode" in
  edit)
    require_vars PR_SUBJECT PR_URL
    subj="$(printf '%s' "$PR_SUBJECT" | strip_draft_prefix)${RM_SUFFIX:-}"
    payload="$($JQ -n --arg subj "$subj" --arg desc "$(pr_description)" \
      '{issue:{subject:$subj,description:$desc}}')" ;;
  note)
    require_vars CMT_URL CMT_USER
    text="$(printf '[%s %s](%s)\n\n%s\n' "$CMT_USER" "${CMT_ACTION:-commented}" "$CMT_URL" "${CMT_BODY:-}" | md_to_textile)"
    payload="$($JQ -n --arg body "$text" '{issue:{notes:$body}}')" ;;
  *) die "Usage: $0 edit|note" ;;
esac

for id in $(rm_find_issues); do
  echo "Updating Redmine issue $id ($mode)"
  printf '%s' "$payload" | rm_send PUT "issues/${id}.json" >/dev/null
done
