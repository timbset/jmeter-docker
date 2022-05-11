#!/bin/bash

if [[ ! -z "$AWS_ACCESS_KEY_ID" ]] && [[ ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  USE_AWS=1
fi

if [[ ! -z "$USE_AWS" ]]; then
  aws --version
  echo "Downloading test plan from ${TEST_PLAN_S3_URI}"
  aws s3 cp ${TEST_PLAN_S3_URI} test-plans/test-plan.jmx
  echo "Test plan downloaded"
fi

/entrypoint.sh -Dlog_level.jmeter=DEBUG -n -t test-plans/test-plan.jmx -l test-plans/test-plan.jtl -j test-plans/jmeter.log

if [[ ! -z "$USE_AWS" ]] && [[ ! -z "$TEST_PLAN_RESULTS_S3_URI_PREFIX" ]]; then
  echo "Uploading results to ${TEST_PLAN_RESULTS_S3_URI_PREFIX}"
  aws s3 cp test-plans/test-plan.jtl "${TEST_PLAN_RESULTS_S3_URI_PREFIX}/${AWS_REQUEST_ID}.jtl"
  echo "Results uploaded"
fi

rm test-plans/test-plan.jtl test-plans/jmeter.log

curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "OK"
