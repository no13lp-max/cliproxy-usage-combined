# Combined runtime for CLIProxyAPI + CPA Usage Keeper on a single Render service.
# This keeps the raw Redis/RESP stats queue on localhost, avoiding Render free private networking limits.
FROM eceasy/cli-proxy-api:latest AS cli
FROM ghcr.io/willxup/cpa-usage-keeper:latest AS keeper

FROM alpine:3.22.0

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    gettext \
    nginx \
    sqlite-libs \
    tzdata

COPY --from=cli /CLIProxyAPI /CLIProxyAPI
COPY --from=keeper /app/cpa-usage-keeper /opt/cpa-usage-keeper/cpa-usage-keeper
COPY --from=keeper /app/web/dist /opt/cpa-usage-keeper/web/dist

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY start.sh /usr/local/bin/start-combined.sh

RUN chmod +x /usr/local/bin/start-combined.sh \
    && mkdir -p /run/nginx /var/log/nginx /data/usage-keeper

ENV TZ=Asia/Shanghai
EXPOSE 10000

CMD ["/usr/local/bin/start-combined.sh"]
