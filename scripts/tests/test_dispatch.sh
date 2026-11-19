. "$(dirname "$0")/lib.sh"
D="$SCRIPTS/redmine_sync.sh"

t_noop() { EVENT_ACTION=push:none "$D" sync >/dev/null; "$D" sync >/dev/null; assert_eq 0 "$(wc -l < "$MOCK_LOG")"; }
t_link() {
  respond "GET issues.json" '{"issues":[]}'; respond "POST issues.json" '{"issue":{"id":1}}'
  EVENT_ACTION=pull_request:opened "$D" sync >/dev/null
  assert_log_has "POST https://rm.test/issues.json"
}
t_reopened() {
  respond "GET issues.json" '{"issues":[]}'; respond "POST issues.json" '{"issue":{"id":1}}'
  EVENT_ACTION=pull_request:reopened "$D" sync >/dev/null
  assert_log_has "POST https://rm.test/issues.json"
}
t_link_removed() { assert_fails "$D" link; }
t_sync_edit() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  EVENT_ACTION=pull_request:edited "$D" sync >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
}
t_draft_events() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  EVENT_ACTION=pull_request:converted_to_draft "$D" sync >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  EVENT_ACTION=pull_request:ready_for_review "$D" sync >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
}
t_gitlab_update() {
  respond "GET merge_requests/41" '{"title":"Draft: Fix thing","description":"body text","draft":true}'
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  PLATFORM=gitlab GITLAB_CI=true GITLAB_TOKEN=token CI_PIPELINE_SOURCE=merge_request_event \
    CI_API_V4_URL=https://gitlab.test/api/v4 CI_PROJECT_ID=12 CI_PROJECT_URL=https://gitlab.test/group/proj \
    CI_MERGE_REQUEST_IID=41 CI_MERGE_REQUEST_STATE=opened CI_MERGE_REQUEST_SOURCE_BRANCH_NAME=feature/x \
    "$D" sync >/dev/null
  assert_log_has "GET https://gitlab.test/api/v4/projects/12/merge_requests/41"
  assert_log_has "PUT https://rm.test/issues/5.json"
  assert_eq "Fix thing" "$(body_of 5 | jq -r .issue.subject)"
}
t_gitlab_closed() {
  respond "GET merge_requests/41" '{"title":"Fix thing","description":"body text","draft":false,"web_url":"https://gitlab.test/group/proj/-/merge_requests/41"}'
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  PLATFORM=gitlab GITLAB_CI=true GITLAB_TOKEN=token CI_PIPELINE_SOURCE=merge_request_event \
    CI_API_V4_URL=https://gitlab.test/api/v4 CI_PROJECT_ID=12 \
    CI_MERGE_REQUEST_IID=41 CI_MERGE_REQUEST_STATE=merged GITLAB_USER_LOGIN=amy \
    "$D" sync >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
  assert_eq "[amy merged](https://gitlab.test/group/proj/-/merge_requests/41)" \
    "$(body_of 3 | jq -r .issue.notes | head -1)"
}
t_review_event() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  echo '{"action":"submitted","review":{"html_url":"http://r","user":{"login":"amy"},"body":"ok","state":"approved"},"pull_request":{}}' > ev.json
  GITHUB_ACTIONS=true GITHUB_EVENT_NAME=pull_request_review GITHUB_EVENT_PATH=$PWD/ev.json "$D" sync >/dev/null
  assert_eq "[amy approved](http://r)" "$(body_of 2 | jq -r .issue.notes | head -1)"
}
t_usage() { assert_fails "$D" bogus; }
for t in t_noop t_reopened t_link_removed t_link t_sync_edit t_draft_events t_gitlab_update t_gitlab_closed t_review_event t_usage; do run_test $t; done
summary
