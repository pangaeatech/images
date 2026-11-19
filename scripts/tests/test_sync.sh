. "$(dirname "$0")/lib.sh"
S="$SCRIPTS/sync_to_redmine.sh"

t_edit() {
  respond "GET issues.json" '{"issues":[{"id":5},{"id":6}]}'
  PR_SUBJECT="Draft: x" DRAFT_PREFIX="Draft: " "$S" edit >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
  assert_log_has "PUT https://rm.test/issues/6.json"
  assert_eq x "$(body_of 2 | jq -r .issue.subject)"
}
t_note() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  CMT_URL=http://c CMT_USER=bob CMT_ACTION=approved CMT_BODY=lgtm "$S" note >/dev/null
  assert_eq "[bob approved](http://c)" "$(body_of 2 | jq -r .issue.notes | head -1)"
}
t_none() { respond "GET issues.json" '{"issues":[]}'; "$S" edit >/dev/null; assert_eq 1 "$(wc -l < "$MOCK_LOG")"; }
t_bad_mode() { assert_fails "$S" bogus; }
for t in t_edit t_note t_none t_bad_mode; do run_test $t; done
summary
