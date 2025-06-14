FROM alpine:latest

RUN apk add --no-cache socat bash

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
