#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${RM_LIB_DIR:-$HERE/lib}"
# shellcheck source=lib/common.sh
. "$LIB/common.sh"

### Single entrypoint for Redmine synchronisation from GitHub Actions or GitLab CI.
### Safe to call from any trigger: unsupported events are a no-op (exit 0).
###  sync          chooses the action from the triggering event:
###                PR opened/reopened/updated -> link_to_redmine.sh (ensure + sync)
###                review submitted     -> sync_to_redmine.sh note
###                PR closed            -> sync_to_redmine.sh note (merged/closed)
###  wiki [F] [P]                      -> update_wiki.sh
###  file [F]                          -> push_file.sh
### (Auto-creating the PR itself is left to workflows/auto-add-pr.yml.)
### GitLab merge_request_event pipelines do not expose GitHub-style actions;
### update events use the idempotent link path, while state supplies closure.
### EVENT_ACTION=<event>:<action> overrides detection (manual:link, manual:edit, manual:note).

cmd="${1:-}"; [ $# -eq 0 ] || shift
echo "Starting Redmine synchronization ($cmd)..."

# event_action : print "<event>:<action>" normalised across platforms
event_action() {
  if [ -n "${EVENT_ACTION:-}" ]; then echo "$EVENT_ACTION"; return; fi
  if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ -n "${GITHUB_EVENT_PATH:-}" ]; then
    echo "${GITHUB_EVENT_NAME:-}:$($JQ -r '.action // empty' "$GITHUB_EVENT_PATH")"
  elif [ "${CI_PIPELINE_SOURCE:-}" = "merge_request_event" ]; then
    case "${CI_MERGE_REQUEST_STATE:-opened}" in
      merged|closed) echo "merge_request:$CI_MERGE_REQUEST_STATE" ;;
      *) echo "merge_request:updated" ;;
    esac
  fi
}

case "$cmd" in
  sync)
    case "$(event_action)" in
      pull_request:opened|pull_request:reopened|pull_request:edited|pull_request:converted_to_draft|pull_request:ready_for_review|pull_request:review_requested|merge_request:opened|merge_request:reopened|merge_request:updated|merge_request:edited|merge_request:converted_to_draft|merge_request:ready_for_review|manual:link)
        exec "$HERE/link_to_redmine.sh" ;;
      manual:edit)
        exec "$HERE/sync_to_redmine.sh" edit ;;
      pull_request_review:submitted|manual:note)
        exec "$HERE/sync_to_redmine.sh" note ;;
      pull_request:closed|merge_request:closed|merge_request:merged)
        if [ "${GITHUB_EVENT_PATH:-}" ] && [ "$($JQ -r '.pull_request.merged // false' "$GITHUB_EVENT_PATH")" = "true" ]; then
          export CMT_ACTION=merged
        elif [ "$(event_action)" = "merge_request:merged" ]; then
          export CMT_ACTION=merged
        else
          export CMT_ACTION=closed
        fi
        if [ -n "${GITHUB_EVENT_PATH:-}" ]; then
          export CMT_USER="${CMT_USER:-$($JQ -r '.sender.login' "$GITHUB_EVENT_PATH")}"
          export CMT_URL="${CMT_URL:-$($JQ -r '.pull_request.html_url // empty' "$GITHUB_EVENT_PATH")}"
        fi
        export CMT_USER="${CMT_USER:-${GITLAB_USER_LOGIN:-${CI_COMMIT_AUTHOR:-gitlab}}}"
        export CMT_BODY=""
        exec "$HERE/sync_to_redmine.sh" note ;;
      *) echo "Event '$(event_action)' not supported for sync; nothing to do." ;;
    esac ;;
  wiki) exec "$HERE/update_wiki.sh" "$@" ;;
  file) exec "$HERE/push_file.sh" "$@" ;;
  *) echo "Usage: $0 sync|wiki|file [args]" >&2; exit 2 ;;
esac
