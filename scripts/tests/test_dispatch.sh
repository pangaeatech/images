. "$(dirname "$0")/lib.sh"
D="$SCRIPTS/redmine_sync.sh"

t_noop() { EVENT_ACTION=push:none "$D" link >/dev/null; "$D" sync >/dev/null; assert_eq 0 "$(wc -l < "$MOCK_LOG")"; }
t_link() {
  respond "GET issues.json" '{"issues":[]}'; respond "POST issues.json" '{"issue":{"id":1}}'
  EVENT_ACTION=pull_request:opened "$D" link >/dev/null
  assert_log_has "POST https://rm.test/issues.json"
}
t_sync_edit() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  EVENT_ACTION=pull_request:edited "$D" sync >/dev/null
  assert_log_has "PUT https://rm.test/issues/5.json"
}
t_review_event() {
  respond "GET issues.json" '{"issues":[{"id":5}]}'
  echo '{"action":"submitted","review":{"html_url":"http://r","user":{"login":"amy"},"body":"ok","state":"approved"},"pull_request":{}}' > ev.json
  GITHUB_ACTIONS=true GITHUB_EVENT_NAME=pull_request_review GITHUB_EVENT_PATH=$PWD/ev.json "$D" sync >/dev/null
  assert_eq "[amy approved](http://r)" "$(body_of 2 | jq -r .issue.notes | head -1)"
}
t_usage() { assert_fails "$D" bogus; }
for t in t_noop t_link t_sync_edit t_review_event t_usage; do run_test $t; done
summary
