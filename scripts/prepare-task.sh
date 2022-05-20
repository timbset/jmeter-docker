#!/bin/bash

if [[ ! -z $AWS_EVENT ]]
then
  COUNT=$(echo $AWS_EVENT | jq .count)
fi

if [[ -z $COUNT ]]
then
  echo "Count is required"

  if [[ ! -z $AWS_LAMBDA_RUNTIME_API ]]
  then
    curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/error" \
      -d "{\"errorMessage\":\"Count is required\",\"errorType\":\"InvalidEventDataException\"}"
  fi

  exit 1
fi

ARRAY="0"
COUNTER=1
MAX=$((COUNT - 1))

while [[ $COUNTER -le $MAX ]]
do
	ARRAY="${ARRAY},${COUNTER}"
	COUNTER=$((COUNTER + 1))
done

if [[ ! -z $AWS_LAMBDA_RUNTIME_API ]]
then
  curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" \
    -d "{\"items\":[$ARRAY]}"
else
  echo "Prepared array: $ARRAY"
fi
