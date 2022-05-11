#!/bin/bash

COUNT=$(echo $AWS_EVENT | jq .count)
ARRAY="0"

COUNTER=COUNT

while [[ $COUNT > 1 ]]; do
	ARRAY="${ARRAY},0"
	COUNT=$((COUNTER - 1))
done

curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "{\"items\":[$ARRAY]}"
