# Platform (GitHub / GitLab) abstraction. Source after common.sh.
#
# load_context populates:
#   PR_NUM PR_URL PR_SUBJECT PR_BODY PR_BRANCH PR_ID (platform-native number)
# and for review/comment events:
#   CMT_URL CMT_USER CMT_BODY CMT_ACTION
# Any of these already set in the environment are left alone, which lets tests
# and non-event workflows (workflow_dispatch etc.) supply them directly.
GITLAB_CURL_AUTH() { printf 'PRIVATE-TOKEN: %s' "${GITLAB_TOKEN:-}"; }

detect_platform() {
  if [ -n "${PLATFORM:-}" ]; then return; fi
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then PLATFORM=github
  elif [ -n "${GITLAB_CI:-}" ]; then PLATFORM=gitlab
  else PLATFORM=none; fi
}

# ev PATH : read a value from the GitHub event payload
ev() { [ -f "${GITHUB_EVENT_PATH:-}" ] || return 0; $JQ -r "$1 // empty" "$GITHUB_EVENT_PATH"; }

load_context() {
  detect_platform
  case "$PLATFORM" in
    github)
      : "${PR_ID:=$(ev .pull_request.number)}"
      : "${PR_URL:=$(ev .pull_request.html_url)}"
      : "${PR_SUBJECT:=$(ev .pull_request.title)}"
      : "${PR_BODY:=$(ev .pull_request.body)}"
      : "${PR_BRANCH:=$(ev .pull_request.head.ref)}"
      : "${CMT_URL:=$(ev .review.html_url)}"
      : "${CMT_USER:=$(ev .review.user.login)}"
      : "${CMT_BODY:=$(ev .review.body)}"
      : "${CMT_ACTION:=$(ev .review.state)}"
      ;;
    gitlab)
      require_vars GITLAB_TOKEN CI_API_V4_URL CI_PROJECT_ID CI_MERGE_REQUEST_IID
      PR_ID="$CI_MERGE_REQUEST_IID"
      local mr
      mr=$($CURL -fsS --header "$(GITLAB_CURL_AUTH)" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$PR_ID")
      PR_URL="${CI_PROJECT_URL:-}/-/merge_requests/$PR_ID"
      PR_SUBJECT=$(printf '%s' "$mr" | $JQ -r '.title')
      PR_BODY=$(printf '%s' "$mr" | $JQ -r '.description // ""')
      PR_BRANCH="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-}"
      ;;
    none) : ;;
    *) die "Unknown PLATFORM '$PLATFORM'" ;;
  esac
  PR_NUM="${PR_NUM:-${RM_PR_PREFIX:-}${PR_ID:-}}"
  : "${DRAFT_PREFIX:=$([ "$PLATFORM" = gitlab ] && echo 'Draft: ' || echo 'WIP ')}"
}

# pr_comment TEXT : post a comment on the PR/MR
pr_comment() {
  case "$PLATFORM" in
    github) $GH pr comment "$PR_URL" -b "$1" ;;
    gitlab)
      $JQ -n --arg b "$1" '{body:$b}' | $CURL -fsS -X POST \
        --header "$(GITLAB_CURL_AUTH)" --header "Content-Type: application/json" \
        --data-binary @- "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$PR_ID/notes" >/dev/null ;;
    *) echo "[no platform] comment: $1" ;;
  esac
}

# pr_draft_and_retitle : if the title carries DRAFT_PREFIX, strip it and mark as draft (GitHub only;
# GitLab treats the "Draft:" prefix natively).
pr_draft_and_retitle() {
  [ "$PLATFORM" = github ] || return 0
  has_prefix "$PR_SUBJECT" "$DRAFT_PREFIX" || return 0
  $GH pr ready "$PR_URL" --undo
  $GH pr edit "$PR_URL" --title "$(printf '%s' "$PR_SUBJECT" | strip_prefix "$DRAFT_PREFIX")"
}
