#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${RM_LIB_DIR:-$HERE/lib}"
# shellcheck source=lib/common.sh
. "$LIB/common.sh"

### Single entrypoint for Redmine synchronisation from GitHub Actions or GitLab CI.
### Safe to call from any trigger: unsupported events are a no-op (exit 0).
###  link          PR opened/reopened   -> link_to_redmine.sh (link to or create an issue)
###  sync          PR edited            -> sync_to_redmine.sh edit
###                review submitted     -> sync_to_redmine.sh note
###                PR closed            -> sync_to_redmine.sh note (merged/closed)
###  wiki [F] [P]                      -> update_wiki.sh
###  file [F]                          -> push_file.sh
### (Auto-creating the PR itself is left to workflows/auto-add-pr.yml.)
### GitLab merge_request_event pipelines map to "opened" (link) / "edited" (sync).

cmd="${1:-}"; [ $# -eq 0 ] || shift
echo "Starting Redmine synchronization ($cmd)..."

# event_action : print "<event>:<action>" normalised across platforms
event_action() {
  if [ -n "${EVENT_ACTION:-}" ]; then echo "$EVENT_ACTION"; return; fi
  if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ -n "${GITHUB_EVENT_PATH:-}" ]; then
    echo "${GITHUB_EVENT_NAME:-}:$($JQ -r '.action // empty' "$GITHUB_EVENT_PATH")"
  elif [ "${CI_PIPELINE_SOURCE:-}" = "merge_request_event" ]; then
    echo "merge_request:opened"
  fi
}

case "$cmd" in
  link)
    case "$(event_action)" in
      pull_request:opened|pull_request:reopened|merge_request:opened|manual:*)
        exec "$HERE/link_to_redmine.sh" "$@" ;;
      *) echo "Event '$(event_action)' not supported for link; nothing to do." ;;
    esac ;;
  sync)
    case "$(event_action)" in
      pull_request:edited|manual:edit)
        exec "$HERE/sync_to_redmine.sh" edit ;;
      pull_request_review:submitted|manual:note)
        exec "$HERE/sync_to_redmine.sh" note ;;
      pull_request:closed)
        if [ "$($JQ -r '.pull_request.merged' "$GITHUB_EVENT_PATH")" = "true" ]; then
          export CMT_ACTION=merged; else export CMT_ACTION=closed; fi
        export CMT_USER="${CMT_USER:-$($JQ -r '.sender.login' "$GITHUB_EVENT_PATH")}"
        export CMT_URL="${CMT_URL:-$($JQ -r '.pull_request.html_url' "$GITHUB_EVENT_PATH")}"
        export CMT_BODY=""
        exec "$HERE/sync_to_redmine.sh" note ;;
      *) echo "Event '$(event_action)' not supported for sync; nothing to do." ;;
    esac ;;
  wiki) exec "$HERE/update_wiki.sh" "$@" ;;
  file) exec "$HERE/push_file.sh" "$@" ;;
  *) echo "Usage: $0 link|sync|wiki|file [args]" >&2; exit 2 ;;
esac
