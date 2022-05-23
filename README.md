# jmeter-docker

## Building image

```bash
docker build -t jmeter-lambda-docker .
```

## Running load tests locally

First, put your JMeter test plan into `test-plans/test-plan.jmx`.
Directory `test-plans` should be mounted to container.
After load test run this directory will contain `test-plan.jml` with results in CSV format
and `jmeter.log` with log information.
Pay attention that results and logs will be deleted on every container run to prevent merge of multiple results.

Then, you need to create `.env` file in the root.

To run tests, use following command:

```bash
docker run --rm --name jmeter-lambda \
  --volume ${PWD}/test-plans:/tmp/test-plans \
  --env-file ./.env \
  -i jmeter-lambda-docker
```

## Supported environment variables

- `TYPE`, possible values
  - runTests - used for running JMeter.
  - prepareTask - used to prepare items array for Map state in AWS Step Function when running in AWS.
It allows running N lambdas at the time.
For example, converts `COUNT=3` into array `[1,2,3]`.
  - buildReport - compiles N results in a single one, then builds HTML report and uploads it to S3
- `AWS_ACCESS_KEY_ID` - used for access to AWS account
- `AWS_SECRET_ACCESS_KEY` - used for access to AWS account
- `TEST_PLAN_S3_URI` - used for downloading test plan from S3.
Requires AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
If it is not specified, tries to execute with plan located in `test-plans/test-plan.jmx`, if exists.
Sample value: `s3://my-bucket/my-plan.jmx`
- `RESULTS_S3_PREFIX` - used to uploading run results to S3 and downloading from S3 to build report.
Requires AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
Puts every result file to following path: `$RESULTS_S3_PREFIX/$EXECUTION_ID/$AWS_REQUEST_ID.jtl`.
If `EXECUTION_ID` is not specified, generates random UUID.
If `AWS_REQUEST_ID` is not specified, uses `results` as default value.
Sample value: `s3://my-bucket/results` 
- `REPORT_S3_URI_PREFIX` - used to upload report in buildReport task.
Requires AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
  Puts every result file to following path: `$RESULTS_S3_PREFIX/$EXECUTION_ID/$AWS_REQUEST_ID.jtl`.
Sample value: `s3://my-bucket/report`
- `JMETER_EXTRA_PARAMS` - used for providing extra parameters for JMeter,
for example, JMeter User Parameters (`-JMyVar1=MyValue1 -JMyVar2=MyValue2`)

## Running in AWS Lambda

### Running tests

```json
{
  "type": "runTests",
  "executionId": "step-function-execution-id",
  "testPlanS3Uri": "s3://path/to-file",
  "testConfigsS3Uri": "s3://path/to/folder",
  "resultsS3Prefix": "s3://path/to/folder",
  "jmeterParams": "-JMyVar1=MyValue2 -JMyVar2=MyValue2",
  "index": 0
}
```

### Preparing task (in AWS Step Function)

```json
{
  "type": "prepareTask",
  "count": 5
}
```

### Building report

```json
{
  "type": "buildReport",
  "executionId": "step-function-execution-id",
  "resultsS3Prefix": "s3://path/to/folder",
  "reportsS3Prefix": "s3://path/to/folder"
}
```
