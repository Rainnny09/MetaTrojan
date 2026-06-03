FROM v2fly/v2fly-core:latest
COPY config.json /etc/v2ray/config.json
ENV PORT 8080
ENTRYPOINT ["v2ray", "run", "-config", "/etc/v2ray/config.json"]