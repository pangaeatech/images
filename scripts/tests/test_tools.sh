# Confirms the real tools the scripts rely on are installed and executable.
# Other tests replace them with mocks, so this is the only check on the real ones.
. "$(dirname "$0")/lib.sh"

t_tool() {
  local tool="$1" path
  path="$(command -v "$tool" 2>/dev/null)" || { nok "$tool not found on PATH"; return; }
  [ -x "$path" ] && ok || nok "$tool at $path is not executable"
}
t_real_tools() {
  local t
  for t in curl sed gh pandoc jq; do t_tool "$t"; done
}
run_test t_real_tools
summary
