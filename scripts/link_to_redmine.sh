set -euo pipefail

if [ -z "${GITLAB_TOKEN:-}" ]; then
  echo "❌ GITLAB_TOKEN not set. Exiting."
  exit 1
fi

echo "Checking labels for MR $CI_MERGE_REQUEST_IID..."

MR_JSON=$(curl -fsS --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID")
LABELS=$(echo "$MR_JSON" | jq -r '.labels[]')

echo "Labels: $LABELS"

PR_NUM="${RM_PR_PREFIX}$CI_MERGE_REQUEST_IID"
PR_URL="$CI_PROJECT_URL/-/merge_requests/$CI_MERGE_REQUEST_IID"

if echo "$LABELS" | grep -iq "redmine"; then
    echo "Merge Request already labeled 'redmine'. Skipping Redmine linking."

    case "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME" in
      # If the source branch is a bot branch, update the Redmine issue # with the new PR info
      dependabot/*)
      renovate/*)
      whitesource/*)
        SUBJ=$(echo "$MR_JSON" | jq -r '.title' | sed -e 's/^Draft: //I')
        PR_BODY=$(echo "$MR_JSON" | jq -r '.description // ""')
        BODY=$(printf 'Linked to [Pull Request %s](%s)\n\n%s\n' "$PR_NUM" "$PR_URL" "$PR_BODY" | pandoc -f gfm -t html | pandoc -f html -t textile | sed -e 's/<tt>/<code>/g' -e 's/<\/tt>/<\/code>/g' -e 's/<hr *\/>/----/g' -e 's/[^ -~].../?/g')
    
        curl -fsS -X GET -H "X-REDMINE-API-KEY: ${REDMINE_TOKEN}" \
            "$RM_URL/issues.json?project_id=${RM_PROJECT_ID}&cf_${RM_FIELD_ID}=${PR_NUM}&status_id=*" > issues.txt
        jq --null-input --arg key "$REDMINE_TOKEN" --arg subj "$SUBJ${RM_SUFFIX:-}" --arg desc "$BODY" '{key:$key,issue:{subject:$subj,description:$desc}}' > body.json
        for RM_ISSUE in $(cat issues.txt | jq '.issues[]?.id'); do
            curl -fsS -X PUT -H "Content-Type: application/json" -d "@body.json" "${RM_URL}/issues/${RM_ISSUE}.json";
        done
        ;;
    esac

    exit 0
fi

RM_ISSUE=$(echo "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME" | sed -n -E 's/^(task|issue|bug)([0-9]+)-.*$/\2/pI')
echo "RM Issue: $RM_ISSUE"

if [ -n "$RM_ISSUE" ]; then 
    echo "Linking MR to Redmine issue $RM_ISSUE"

    BODY=$(echo "Linked to \"Pull Request $PR_NUM\":$PR_URL")
    jq --null-input \
        --arg key "$REDMINE_TOKEN" \
        --arg body "$BODY" \
        --arg prnum "$PR_NUM" \
        --arg fld "$RM_FIELD_ID" \
        '{key:$key,issue:{notes:$body,custom_fields:[{value:$prnum,id:$fld}]}}' > body.json
    curl -fsS -X PUT -H "Content-Type: application/json" -d "@body.json" "${RM_URL}/issues/${RM_ISSUE}.json"
else
    echo "Creating new Redmine issue..."
    SUBJ=$(echo "$MR_JSON" | jq -r '.title' | sed -e 's/^Draft: //I')
    PR_BODY=$(echo "$MR_JSON" | jq -r '.description // ""')
    BODY=$(printf 'Linked to [Pull Request %s](%s)\n\n%s\n' "$PR_NUM" "$PR_URL" "$PR_BODY" | pandoc -f gfm -t html | pandoc -f html -t textile | sed -e 's/<tt>/<code>/g' -e 's/<\/tt>/<\/code>/g' -e 's/<hr *\/>/----/g' -e 's/[^ -~].../?/g')
    jq --null-input \
        --arg key "$REDMINE_TOKEN" \
        --arg subj "$SUBJ${RM_SUFFIX:-}" \
        --arg desc "$BODY" \
        --arg proj "$RM_PROJECT_ID" \
        --arg trac "$RM_TRACKER_ID" \
        --arg vers "$RM_VERSION_ID" \
        --arg prnum "$PR_NUM" \
        --arg fld "$RM_FIELD_ID" \
        '{key:$key,issue:{project_id:$proj,tracker_id:$trac,subject:$subj,description:$desc,fixed_version_id:$vers,custom_fields:[{value:$prnum,id:$fld}]}}' > body.json
    curl -fsS -X POST -H "Content-Type: application/json" -d "@body.json" "$RM_URL/issues.json" > issue.txt

    TaskId=$(cat issue.txt | jq '.issue.id')
    if [ -z "$TaskId" -o "$TaskId" = "null" ]; then
        cat issue.txt
        exit 1
    else
        curl -fsS --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" \
            --data "{\"body\": \"Added as [Redmine Task $TaskId]($RM_URL/issues/$TaskId)\"}" \
            "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes"
    fi;
fi

echo "Adding 'redmine' label to MR..."
UPDATED_LABELS="$(echo "$LABELS" | tr '\n' ',' | sed 's/,$//'),redmine"
curl -fsS --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"labels\": \"$UPDATED_LABELS\"}" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID"
