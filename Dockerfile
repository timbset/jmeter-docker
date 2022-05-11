FROM justb4/jmeter:latest

RUN apk add --no-cache zip aws-cli jq

COPY run-jmeter.sh /
COPY run-tests.sh /
COPY build-report.sh /

WORKDIR /tmp

ENTRYPOINT ["/run-jmeter.sh"]
