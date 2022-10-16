FROM docker:20.10.12-dind

RUN apk --no-cache add git curl git-lfs
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
