#!/bin/bash

if [[ ! -z $AWS_EVENT ]]
then
  EXECUTION_ID=$(echo $AWS_EVENT | jq .executionId | awk -F ":" '{print $8}' | tr -d '"')
  RESULTS_S3_PREFIX=$(echo $AWS_EVENT | jq .resultsS3Prefix | tr -d '"')
  TEST_PLAN_S3_URI=$(echo $AWS_EVENT | jq .testPlanS3Uri | tr -d '"')
  TEST_CONFIGS_S3_URI=$(echo $AWS_EVENT | jq .testConfigsS3Uri | tr -d '"')
  JMETER_EXTRA_PARAMS=$(echo $AWS_EVENT | jq .jmeterParams | tr -d '"')
  INDEX=$(echo $AWS_EVENT | jq .index)
else
  EXECUTION_ID=$(uuidgen | awk '{print tolower($0)}')
  echo "Execution ID is ${EXECUTION_ID}"
fi

if [[ "$JMETER_EXTRA_PARAMS" == null ]]
then
  JMETER_EXTRA_PARAMS=
fi

rm test-plans/jmeter.log test-plans/test-plan.jtl 2> /dev/null

if [[ ! -z $USE_AWS ]] && [[ ! -z $TEST_PLAN_S3_URI ]]
then
  rm test-plans/test-plan.jmx 2> /dev/null

  echo "Downloading test plan from ${TEST_PLAN_S3_URI}" \
    && aws s3 cp "${TEST_PLAN_S3_URI}" test-plans/test-plan.jmx \
    && echo "Test plan downloaded" \
    || echo "Failed to download plan"
fi

if [[ ! -z $USE_AWS ]] && [[ ! -z $TEST_CONFIGS_S3_URI ]]
then
  rm -rf test-plans/configs 2> /dev/null

  echo "Downloading test configs from ${TEST_CONFIGS_S3_URI}" \
    && aws s3 cp "${TEST_CONFIGS_S3_URI}" test-plans/configs --recursive \
    && echo "Test configs downloaded" \
    || echo "Failed to download configs"
fi

/entrypoint.sh -n -t test-plans/test-plan.jmx \
  -l test-plans/test-plan.jtl \
  -j test-plans/jmeter.lo -e \
  ${JMETER_EXTRA_PARAMS//\$INDEX/$INDEX}

if [[ ! -z $USE_AWS ]] && [[ ! -z $RESULTS_S3_PREFIX ]]
then
  echo "Uploading results to ${RESULTS_S3_PREFIX}/${EXECUTION_ID}" \
    && aws s3 cp test-plans/test-plan.jtl "${RESULTS_S3_PREFIX}/${EXECUTION_ID}/${AWS_REQUEST_ID:-result}.jtl" \
    && echo "Results uploaded" \
    || echo "Results upload failed"
fi

if [[ ! -z $AWS_LAMBDA_RUNTIME_API ]]
then
  curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "OK"
fi
