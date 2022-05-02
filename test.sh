#!/bin/bash

docker run --rm --name jmeter-lambda \
  -w ${PWD}/test-plans:/workdir/test-plans \
  --env-file ./.env \
  -i jmeter-lambda-docker
