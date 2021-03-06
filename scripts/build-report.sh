#!/bin/bash

if [[ ! -z $AWS_EVENT ]]
then
  EXECUTION_ID=$(echo $AWS_EVENT | jq .executionId | awk -F ":" '{print $8}' | tr -d '"')
  RESULTS_S3_PREFIX=$(echo $AWS_EVENT | jq .resultsS3Prefix | tr -d '"')
  REPORTS_S3_PREFIX=$(echo $AWS_EVENT | jq .reportsS3Prefix | tr -d '"')
fi

rm -rf results report 2> /dev/null
rm result.jtl report.zip 2> /dev/null

if [[ ! -z $USE_AWS ]]
then
  echo "Downloading results from ${RESULTS_S3_PREFIX}/${EXECUTION_ID}" \
    && aws s3 cp "${RESULTS_S3_PREFIX}/${EXECUTION_ID}" results --recursive \
    && echo "Results downloaded"
fi

echo "Merging results"
head -n 1 $(find results/*.jtl | head -n 1) > result.jtl && tail -n +2 -q results/*.jtl >> result.jtl

echo "Results merged. Building report"
/entrypoint.sh -g result.jtl -o report && zip -q -r -9 report.zip report
echo "Report built"

if [[ ! -z $USE_AWS ]]
then
  echo "Uploading merge results to ${RESULTS_S3_PREFIX}/${EXECUTION_ID}"
  aws s3 cp result.jtl "${RESULTS_S3_PREFIX}/${EXECUTION_ID}/all.jtl"
  echo "Results uploaded"
fi

if [[ ! -z $USE_AWS ]]
then
  echo "Uploading report ${REPORTS_S3_PREFIX}"
  aws s3 cp report.zip "${REPORTS_S3_PREFIX}/${EXECUTION_ID}.zip"
  echo "Results uploaded"
  REPORT_URL=$(aws s3 presign "${REPORTS_S3_PREFIX}/${EXECUTION_ID}.zip")
  echo "Report URL: $REPORT_URL"
fi

if [[ ! -z AWS_LAMBDA_RUNTIME_API ]]
then
  curl -X POST -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$AWS_REQUEST_ID/response" \
    -d "{\"reportUrl\":\"$REPORT_URL\"}"
fi
