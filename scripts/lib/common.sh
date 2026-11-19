# Shared helpers for the Redmine sync scripts. Source this file; do not execute it.
#
# Every external program is invoked through an overridable variable so tests
# can substitute mocks, e.g.  CURL=/path/to/mock-curl ./link_to_redmine.sh
CURL="${CURL:-curl}"
JQ="${JQ:-jq}"
PANDOC="${PANDOC:-pandoc}"
GH="${GH:-gh}"
SED="${SED:-sed}"

die() { echo "❌ $*" >&2; exit 1; }

# require_vars NAME... : abort if any named variable is unset or empty
require_vars() {
  local v
  for v in "$@"; do
    [ -n "${!v:-}" ] || die "$v not set. Exiting."
  done
}

# Normalise the Redmine URL (no trailing slash)
rm_init() {
  require_vars RM_URL REDMINE_TOKEN
  RM_URL="${RM_URL%/}"
}

# rm_get PATH : GET $RM_URL/PATH, print the response
rm_get() {
  $CURL -fsS -X GET -H "X-Redmine-API-Key: ${REDMINE_TOKEN}" "$RM_URL/$1"
}

# rm_send METHOD PATH : send JSON read from stdin, print the response.
# The API key travels in a header so it never lands in a body file on disk.
rm_send() {
  $CURL -fsS -X "$1" -H "X-Redmine-API-Key: ${REDMINE_TOKEN}" \
    -H "Content-Type: application/json" --data-binary @- "$RM_URL/$2"
}

# rm_find_issues : print ids (one per line) of issues linked to $PR_NUM
rm_find_issues() {
  require_vars RM_PROJECT_ID RM_FIELD_ID PR_NUM
  rm_get "issues.json?project_id=${RM_PROJECT_ID}&cf_${RM_FIELD_ID}=${PR_NUM}&status_id=*" \
    | $JQ -r '.issues[]?.id'
}

# md_to_textile : stdin markdown -> stdout textile (Redmine friendly)
md_to_textile() {
  $PANDOC -f gfm -t html | $PANDOC -f html -t textile \
    | $SED -e 's/<tt>/<code>/g' -e 's/<\/tt>/<\/code>/g' -e 's/<hr *\/>/----/g' \
    | strip_4byte
}

# strip_4byte : replace characters outside the BMP (MySQL utf8mb3 cannot store them)
strip_4byte() {
  $JQ -Rrs 'explode | map(if . > 65535 then 65533 else . end) | implode'
}

# strip_prefix PREFIX : stdin -> stdout with a case-insensitive leading prefix removed
strip_prefix() {
  local p="$1" s
  s="$(cat)"
  if [ -n "$p" ] && [[ "${s,,}" == "${p,,}"* ]]; then s="${s:${#p}}"; fi
  printf '%s' "$s"
}

# has_prefix STRING PREFIX
has_prefix() { [ -n "$2" ] && [[ "${1,,}" == "${2,,}"* ]]; }

# branch_issue BRANCH : print N if BRANCH looks like task|issue|bug<N>-...
branch_issue() {
  printf '%s\n' "$1" | $SED -n -E 's/^(task|issue|bug)([0-9]+)-.*$/\2/pI'
}

# is_bot_branch BRANCH
is_bot_branch() {
  case "$1" in dependabot/*|renovate/*|whitesource/*) return 0 ;; esac
  return 1
}

# pr_description : textile body "Linked to PR ..." + PR_BODY
pr_description() {
  printf 'Linked to [Pull Request %s](%s)\n\n%s\n' "$PR_NUM" "$PR_URL" "${PR_BODY:-}" | md_to_textile
}
