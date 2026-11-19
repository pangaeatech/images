#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${RM_LIB_DIR:-$HERE/lib}"
# shellcheck source=lib/common.sh
. "$LIB/common.sh"
# shellcheck source=lib/platform.sh
. "$LIB/platform.sh"

# Links a PR/MR to Redmine.
#  - branch named task|issue|bug<N>-...  -> link to existing Redmine issue N
#  - otherwise                           -> create a new Redmine issue
# Idempotent: if an issue already carries this PR number, nothing is created
# (bot branches get their subject/description refreshed instead).
#
# Env: RM_URL REDMINE_TOKEN RM_PROJECT_ID RM_FIELD_ID RM_TRACKER_ID RM_VERSION_ID
#      [RM_SUFFIX] [RM_PR_PREFIX] [DRAFT_PREFIX], plus PR_* (see lib/platform.sh)

rm_init
load_context
require_vars RM_PROJECT_ID RM_FIELD_ID PR_NUM PR_URL

existing="$(rm_find_issues)"
if [ -n "$existing" ]; then
  echo "PR $PR_NUM already linked to Redmine issue(s): $(echo $existing). Skipping linking."
  if is_bot_branch "${PR_BRANCH:-}"; then
    exec "$HERE/sync_to_redmine.sh" edit
  fi
  exit 0
fi

issue="$(branch_issue "${PR_BRANCH:-}")"
if [ -n "$issue" ]; then
  echo "Linking PR to Redmine issue $issue"
  $JQ -n --arg body "Linked to \"Pull Request $PR_NUM\":$PR_URL" --arg prnum "$PR_NUM" --arg fld "$RM_FIELD_ID" \
    '{issue:{notes:$body,custom_fields:[{value:$prnum,id:$fld}]}}' | rm_send PUT "issues/${issue}.json"
  pr_comment "Linked to [Redmine Task ${issue}]($RM_URL/issues/${issue})"
else
  require_vars RM_TRACKER_ID PR_SUBJECT
  echo "Creating new Redmine issue..."
  subj="$(printf '%s' "$PR_SUBJECT" | strip_prefix "$DRAFT_PREFIX")${RM_SUFFIX:-}"
  desc="$(pr_description)"
  resp="$($JQ -n --arg subj "$subj" --arg desc "$desc" --arg proj "$RM_PROJECT_ID" \
      --arg trac "$RM_TRACKER_ID" --arg vers "${RM_VERSION_ID:-}" --arg prnum "$PR_NUM" --arg fld "$RM_FIELD_ID" \
      '{issue:({project_id:$proj,tracker_id:$trac,subject:$subj,description:$desc,custom_fields:[{value:$prnum,id:$fld}]}
        + (if $vers == "" then {} else {fixed_version_id:$vers} end))}' | rm_send POST issues.json)"
  issue="$(printf '%s' "$resp" | $JQ -r '.issue.id // empty')"
  [ -n "$issue" ] || { echo "$resp" >&2; die "Redmine did not return an issue id"; }
  pr_comment "Added as [Redmine Task $issue]($RM_URL/issues/$issue)"
fi

pr_draft_and_retitle
