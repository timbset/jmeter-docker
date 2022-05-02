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

/entrypoint.sh -Dlog_level.jmeter=DEBUG -n -t test-plans/test-plan.jmx -l test-plans/test-plan.jtl -j test-plans/jmeter.log -e -o report/
zip -r -9 -q report.zip report/

if [[ ! -z "$USE_AWS" ]] && [[ ! -z "$TEST_PLAN_REPORT_S3_URI" ]]; then
  echo "Uploading report to ${TEST_PLAN_REPORT_S3_URI}"
  aws s3 cp report.zip ${TEST_PLAN_REPORT_S3_URI}
  echo "Report uploaded"
fi

rm test-plans/test-plan.jtl test-plans/jmeter.log && rm -rf report/
