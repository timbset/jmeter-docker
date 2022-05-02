FROM justb4/jmeter:latest

RUN apk add --no-cache aws-cli

COPY run-jmeter.sh /

WORKDIR /workdir

ENTRYPOINT ["/run-jmeter.sh"]
