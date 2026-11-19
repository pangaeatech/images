#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${RM_LIB_DIR:-$HERE/lib}"
# shellcheck source=lib/common.sh
. "$LIB/common.sh"
# shellcheck source=lib/platform.sh
. "$LIB/platform.sh"

# Uploads a file to Redmine (up to the server's attachment size limit).
# Usage: push_file.sh [FILE...]      (or FILEPATH env)
# Env:   RM_URL REDMINE_TOKEN, and one target:
#   RM_ISSUE_ID                -> attach to that issue
#   RM_PROJECT_ID [+ RM_VERSION_ID] -> project "Files", optionally under a version
# Issue wins over version/project when several are given.

rm_init
[ $# -gt 0 ] || set -- "${FILEPATH:-}"
for file in "$@"; do
  require_vars file
  [ -f "$file" ] || die "File '$file' not found"
done

push_one() {
  local file="$1" name ctype token upload
  name="$(basename "$file")"
  ctype="${FILE_CONTENT_TYPE:-application/octet-stream}"

  # Step 1: upload the bytes, receive a token
  upload="$($CURL -fsS -X POST -H "X-Redmine-API-Key: ${REDMINE_TOKEN}" -H "Content-Type: application/octet-stream" \
    --data-binary "@${file}" "$RM_URL/uploads.json?filename=$($JQ -rn --arg n "$name" '$n|@uri')")"
  token="$(printf '%s' "$upload" | $JQ -r '.upload.token // empty')"
  [ -n "$token" ] || { echo "$upload" >&2; die "Redmine did not return an upload token"; }

  # Step 2: attach the token
  if [ -n "${RM_ISSUE_ID:-}" ]; then
    $JQ -n --arg t "$token" --arg n "$name" --arg c "$ctype" \
      '{issue:{uploads:[{token:$t,filename:$n,content_type:$c}]}}' | rm_send PUT "issues/${RM_ISSUE_ID}.json" >/dev/null
  else
    require_vars RM_PROJECT_ID
    $JQ -n --arg t "$token" --arg n "$name" --arg v "${RM_VERSION_ID:-}" \
      '{file:({token:$t,filename:$n} + (if $v == "" then {} else {version_id:$v} end))}' \
      | rm_send POST "projects/${RM_PROJECT_ID}/files.json" >/dev/null
  fi
  echo "Uploaded $name"
}

for file in "$@"; do push_one "$file"; done
