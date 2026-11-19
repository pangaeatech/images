. "$(dirname "$0")/lib.sh"
. "$SCRIPTS/lib/common.sh"

t_prefix() {
  assert_eq "Fix" "$(printf 'wip Fix' | strip_prefix 'WIP ')"
  assert_eq "Fix" "$(printf 'Fix' | strip_prefix 'WIP ')"
  has_prefix "Draft: x" "draft: " && ok || nok has_prefix
  has_prefix "x" "" && nok empty-prefix || ok
}
t_branch() {
  assert_eq 42 "$(branch_issue 'Task42-foo')"
  assert_eq "" "$(branch_issue 'feature/x')"
  is_bot_branch renovate/foo && ok || nok bot
  is_bot_branch main && nok notbot || ok
}
t_4byte() {
  assert_eq "a�b" "$(printf 'a😀b' | strip_4byte)"
  assert_eq "é" "$(printf 'é' | strip_4byte)"
}
t_require() { assert_fails bash -c ". $SCRIPTS/lib/common.sh; unset NOPE; require_vars NOPE"; }
for t in t_prefix t_branch t_4byte t_require; do run_test $t; done
summary
