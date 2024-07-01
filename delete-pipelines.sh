#!/bin/bash
set -e

# Gitlab URL
PIPELINES=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines

# Grand access
TOKEN=${CI_CLEANUP}

# How many to delete from the oldest, 100 is the maximum, above will just remove 100.
PER_PAGE=100

# All pipelines older than 14 days
UPDATED_BEFORE=$(date -d '14 days ago' +%Y-%m-%d)

echo "Delete the $PER_PAGE oldest piplines created before $UPDATED_BEFORE"

# iterate over pipelines and delete
for PIPELINE in $(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$PIPELINES?per_page=$PER_PAGE&sort=asc&updated_before=$UPDATED_BEFORE" | jq '.[].id') ; do
    echo "Deleting pipeline $PIPELINE"
    curl --header "PRIVATE-TOKEN: $TOKEN" --request "DELETE" "$PIPELINES/$PIPELINE"
done
