#!/bin/bash

EXECUTION_ID=$(echo $AWS_EVENT | jq .executionId | awk -F ":" '{print $8}' | tr -d '"')
RESULTS_S3_PREFIX=$(echo $AWS_EVENT | jq .resultsS3Prefix | tr -d '"')
TEST_PLAN_S3_URI=$(echo $AWS_EVENT | jq .testPlanS3Uri | tr -d '"')

if [[ ! -z "$AWS_ACCESS_KEY_ID" ]] && [[ ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  USE_AWS=1
fi

if [[ ! -z "$USE_AWS" ]]; then
  echo "Downloading test plan from ${TEST_PLAN_S3_URI}" \
    && aws s3 cp "${TEST_PLAN_S3_URI}" test-plans/test-plan.jmx \
    && echo "Test plan downloaded" \
    || echo "Failed to download plan"
fi

/entrypoint.sh -n -t test-plans/test-plan.jmx -l test-plans/test-plan.jtl -j test-plans/jmeter.lo -e

if [[ ! -z "$USE_AWS" ]] && [[ ! -z "$RESULTS_S3_PREFIX" ]]; then
  echo "Uploading results to ${RESULTS_S3_PREFIX}/${EXECUTION_ID}" \
    && aws s3 cp test-plans/test-plan.jtl "${RESULTS_S3_PREFIX}/${EXECUTION_ID}/${AWS_REQUEST_ID}.jtl" \
    && echo "Results uploaded" \
    || echo "Results upload failed"
fi

rm test-plans/test-plan.jtl test-plans/jmeter.log

curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "OK"
