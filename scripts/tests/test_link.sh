. "$(dirname "$0")/lib.sh"
L="$SCRIPTS/link_to_redmine.sh"

t_create() {
  respond "GET issues.json" '{"issues":[]}'
  respond "POST issues.json" '{"issue":{"id":99}}'
  PR_SUBJECT="WIP Fix thing" RM_SUFFIX=" [x]" "$L" >/dev/null
  assert_log_has "POST https://rm.test/issues.json"
  assert_log_has "cf_11=7"
  assert_eq "Fix thing [x]" "$(body_of 2 | jq -r .issue.subject)"
  assert_eq 10 "$(body_of 2 | jq -r .issue.fixed_version_id)"
  assert_log_has "gh pr comment https://gh/pr/7 -b Added as [Redmine Task 99](https://rm.test/issues/99)"
  assert_log_has "gh pr ready https://gh/pr/7 --undo"
  assert_log_has "gh pr edit https://gh/pr/7 --title Fix thing"
  assert_log_lacks secret
}
t_link_branch() {
  respond "GET issues.json" '{"issues":[]}'
  PR_BRANCH=bug123-fix "$L" >/dev/null
  assert_log_has "PUT https://rm.test/issues/123.json"
  assert_eq 7 "$(body_of 2 | jq -r '.issue.custom_fields[0].value')"
  assert_log_has "Linked to [Redmine Task 123]"
  assert_log_lacks "POST https://rm.test/issues.json"
}
t_existing_refresh() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  "$L" >/dev/null
  assert_eq 3 "$(wc -l < "$MOCK_LOG")"
  assert_log_has "PUT https://rm.test/issues/5.json"
}
t_bot_refresh() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  PR_BRANCH=renovate/foo "$L" >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
}
t_native_draft() {
  respond "GET issues.json" '{"issues":[]}'
  respond "POST issues.json" '{"issue":{"id":99}}'
  PR_SUBJECT="Draft: Fix thing" PR_DRAFT=true "$L" >/dev/null
  assert_eq "Fix thing" "$(body_of 2 | jq -r .issue.subject)"
  assert_log_lacks "gh pr ready"
  assert_log_has "gh pr edit https://gh/pr/7 --title Fix thing"
}
t_no_tracker() { unset RM_TRACKER_ID; respond "GET issues.json" '{"issues":[]}'; assert_fails "$L"; }
t_no_id() { respond "GET issues.json" '{"issues":[]}'; respond "POST issues.json" '{"error":1}'; assert_fails "$L"; }
for t in t_create t_link_branch t_existing_refresh t_bot_refresh t_native_draft t_no_tracker t_no_id; do run_test $t; done
summary
