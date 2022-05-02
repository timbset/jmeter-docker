FROM justb4/jmeter:latest

RUN apk add --no-cache zip aws-cli

COPY run-jmeter.sh /

WORKDIR /tmp

ENTRYPOINT ["/run-jmeter.sh"]
