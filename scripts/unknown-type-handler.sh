#!/bin/bash

ERROR_MESSAGE="Unknown event type: \"$TYPE\""

if [[ ! -z $AWS_LAMBDA_RUNTIME_API ]]
then
  ERROR="{\"errorMessage\":\"$ERROR_MESSAGE\",\"errorType\":\"InvalidEventDataException\"}"

  curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/error" \
    -H "Lambda-Runtime-Function-Error-Type: Runtime.Unhandled" \
    -d "$ERROR"
else
  echo $ERROR_MESSAGE
fi
