. "$(dirname "$0")/lib.sh"

t_wiki() {
  echo "# hi" > wiki.markdown
  CI_PROJECT_NAME=repo "$SCRIPTS/update_wiki.sh" >/dev/null
  assert_log_has "PUT https://rm.test/projects/proj/wiki/Renovate_repo.json"
  assert_eq "# hi" "$(body_of 1 | jq -r .wiki_page.text | head -1)"
}
t_wiki_missing() { assert_fails "$SCRIPTS/update_wiki.sh" nofile; }
t_file_project() {
  echo data > a.zip
  respond "POST uploads.json" '{"upload":{"token":"tok"}}'
  "$SCRIPTS/push_file.sh" a.zip >/dev/null
  assert_log_has "POST https://rm.test/uploads.json?filename=a.zip file:a.zip"
  assert_log_has "POST https://rm.test/projects/proj/files.json"
  assert_eq 10 "$(body_of 2 | jq -r .file.version_id)"
}
t_file_issue() {
  echo data > a.zip
  respond "POST uploads.json" '{"upload":{"token":"tok"}}'
  RM_ISSUE_ID=3 "$SCRIPTS/push_file.sh" a.zip >/dev/null
  assert_log_has "PUT https://rm.test/issues/3.json"
  assert_eq tok "$(body_of 2 | jq -r '.issue.uploads[0].token')"
}
t_file_notoken() { echo d > a; assert_fails "$SCRIPTS/push_file.sh" a; }
for t in t_wiki t_wiki_missing t_file_project t_file_issue t_file_notoken; do run_test $t; done
summary
