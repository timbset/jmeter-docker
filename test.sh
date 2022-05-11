#!/bin/bash

docker run --rm --name jmeter-lambda \
  --volume ${PWD}/test-plans:/tmp/test-plans \
  --env-file ./.env \
  -i jmeter-lambda-docker
