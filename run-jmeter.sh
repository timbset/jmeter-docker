#!/bin/bash

AWS_REQUEST_ID=$(curl --head -X GET -s -H "User-Agent: custom-agent" "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next" | grep "Lambda-Runtime-Aws-Request-Id" | cut -c 32-67)

if [[ ! -z "$AWS_ACCESS_KEY_ID" ]] && [[ ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  USE_AWS=1
fi

if [[ ! -z "$USE_AWS" ]]; then
  aws --version
  echo "Downloading test plan from ${TEST_PLAN_S3_URI}"
  aws s3 cp ${TEST_PLAN_S3_URI} test-plans/test-plan.jmx
  echo "Test plan downloaded"
fi

/entrypoint.sh -Dlog_level.jmeter=DEBUG -n -t test-plans/test-plan.jmx -l test-plans/test-plan.jtl -j test-plans/jmeter.log -e -o report/
zip -r -9 -q report.zip report/

if [[ ! -z "$USE_AWS" ]] && [[ ! -z "$TEST_PLAN_REPORT_S3_URI_PREFIX" ]]; then
  echo "Uploading report to ${TEST_PLAN_REPORT_S3_URI}"
  aws s3 cp report.zip "${TEST_PLAN_REPORT_S3_URI_PREFIX}/${AWS_REQUEST_ID}.zip"
  echo "Report uploaded"
fi

rm test-plans/test-plan.jtl test-plans/jmeter.log && rm -rf report/

curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "OK"
