# Minimal test harness. Source from test files.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$TESTS_DIR/.." && pwd)"
PASS=0 FAIL=0

# setup : fresh sandbox with mocks wired in and a clean environment
setup() {
  T="$(mktemp -d)"
  export MOCK_LOG="$T/calls.log" MOCK_RESPONSES="$T/responses"
  : > "$MOCK_LOG"; : > "$MOCK_RESPONSES"
  export CURL="$TESTS_DIR/mocks/curl" GH="$TESTS_DIR/mocks/gh" PANDOC="$TESTS_DIR/mocks/pandoc"
  while IFS= read -r v; do unset "$v"; done < <(env | cut -d= -f1 | grep -E '^(GITHUB_|GITLAB_|CI_|RM_|PR_|CMT_|PLATFORM|EVENT_ACTION|DRAFT_|WIKI_|FILE|PROJECT_NAME)' || true)
  export RM_URL=https://rm.test/ REDMINE_TOKEN=secret RM_PROJECT_ID=proj RM_FIELD_ID=11 RM_TRACKER_ID=13 RM_VERSION_ID=10
  export PLATFORM=github PR_ID=7 PR_NUM=7 PR_URL=https://gh/pr/7 PR_SUBJECT="Fix thing" PR_BODY="body text" PR_BRANCH=feature/x
  cd "$T"
}
respond() { echo "$1|$2" >> "$MOCK_RESPONSES"; }

ok()   { PASS=$((PASS+1)); }
nok()  { FAIL=$((FAIL+1)); echo "  FAIL: $*"; }
assert_log_has()   { grep -qF -- "$1" "$MOCK_LOG" && ok || nok "log missing '$1'$(printf '\n--- log ---\n'; cat "$MOCK_LOG")"; }
assert_log_lacks() { grep -qF -- "$1" "$MOCK_LOG" && nok "log unexpectedly has '$1'" || ok; }
assert_eq()        { [ "$1" = "$2" ] && ok || nok "expected '$1' got '$2' ${3:-}"; }
assert_fails()     { if "$@" >/dev/null 2>&1; then nok "expected failure: $*"; else ok; fi; }
# body_of N : JSON body of the Nth logged call
body_of() { sed -n "${1}p" "$MOCK_LOG" | cut -d' ' -f3-; }

run_test() { echo "- $1"; setup; "$1"; }
summary() { echo "passed=$PASS failed=$FAIL"; [ "$FAIL" -eq 0 ]; }
