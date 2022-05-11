#!/bin/bash

if [[ ! -z "$AWS_ACCESS_KEY_ID" ]] && [[ ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  export USE_AWS=1
fi

export AWS_REQUEST_ID=$(curl --head -X GET -s -H "User-Agent: custom-agent" "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next" \
  | grep "Lambda-Runtime-Aws-Request-Id" \
  | cut -c 32-67)

export AWS_EVENT=$(curl -X GET -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
TYPE=$(echo $AWS_EVENT | jq .type | tr -d '"')

case $TYPE in

  prepareTask)
    /prepare-task.sh
    ;;

  runTests)
    /run-tests.sh
    ;;

  buildReport)
    /build-report.sh
    ;;

  *)
    ERROR="{\"errorMessage\":\"Unknown event type: \\\"$TYPE\\\"\",\"errorType\":\"InvalidEventDataException\"}"
    curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/error" -d "$ERROR" --header "Lambda-Runtime-Function-Error-Type: Runtime.Unhandled"
    ;;
esac
