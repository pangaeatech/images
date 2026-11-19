#!/bin/bash
# Runs every test_*.sh in this directory. Needs bash and jq; curl/gh/pandoc are mocked.
cd "$(dirname "$0")"
rc=0
for f in test_*.sh; do
  echo "== $f"
  bash "$f" || rc=1
done
exit $rc
