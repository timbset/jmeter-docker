FROM justb4/jmeter:latest

RUN apk add --no-cache zip aws-cli jq

COPY scripts/handler.sh /
COPY scripts/run-tests.sh /
COPY scripts/build-report.sh /
COPY scripts/prepare-task.sh /

RUN chmod +x /handler.sh /run-tests.sh /build-report.sh /prepare-task.sh

WORKDIR /tmp

ENTRYPOINT ["/handler.sh"]
