#!/bin/bash

AWS_REQUEST_ID=$(curl --head -X GET -s -H "User-Agent: custom-agent" "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next" | grep "Lambda-Runtime-Aws-Request-Id" | cut -c 32-67)
AWS_EXECUTION=$(curl -X GET -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")

echo "Downloading results from ${TEST_PLAN_RESULTS_S3_URI_PREFIX}"
aws s3 cp --recursive "${TEST_PLAN_RESULTS_S3_URI_PREFIX}/results" test-plans/results
echo "Results downloaded"

echo "Merging results"
head -n 1 $(find results/*.jtl | head -n 1) > result.csv && tail -n +2 -q results/*.jtl >> result.jtl
echo "Results merged. Building report"
/entrypoint -g result.jtl -o report && zip -q -r -9 report.zip report
echo "Report built"

echo "Uploading merge results to ${TEST_PLAN_RESULTS_S3_URI_PREFIX}"
aws s3 cp result.jtl "${TEST_PLAN_RESULTS_S3_URI_PREFIX}/results/merged.jtl"
echo "Results uploaded"

echo "Uploading report ${TEST_PLAN_RESULTS_S3_URI_PREFIX}"
aws s3 cp report.zip "${TEST_PLAN_RESULTS_S3_URI_PREFIX}/report.zip"
echo "Results uploaded"

curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" -d "OK"
