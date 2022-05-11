FROM justb4/jmeter:latest

RUN apk add --no-cache zip aws-cli jq

COPY scripts/handler.sh /
COPY scripts/run-tests.sh /
COPY scripts/build-report.sh /

WORKDIR /tmp

ENTRYPOINT ["/handler.sh"]
