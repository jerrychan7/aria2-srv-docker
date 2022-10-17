
FROM alpine:latest

LABEL maintner="jerrychan7@github"

ARG ARIA2_VER=
ENV PUID=1000 \
    PGID=1000 \
    UMASK=022 \
    RPC_SECRET= \
    RPC_PORT=6800 \
    BT_PORT=6888 \
    DHT_PORT= \
    WEAK_DEVICE=false \
    FILE_ALLOCATION=none \
    IPV6_MODE=false \
    TZ=Asia/Shanghai \
    UPDATE_TRACKERS=true \
    CUSTOM_TRACKER_URL= \
    RENAME_TORRENT=true \
    AUTO_DEL_CTRL_FILE=true \
    AUTO_DEL_TORRENT=false \
    AUTO_RM_EMPTY_DIR=false \
    ENABLE_DUP_TASKS=false \
    RECYCLE_BIN=true \
    UNCOM_FILE_AUTO_RM=true

RUN set -ex \
 && sed "s@\(alpinelinux.org\/alpine\/\).*\/@\1edge\/@" /etc/apk/repositories >> /etc/apk/repositories \
 && apk update \
 && apk add --upgrade aria2=${ARIA2_VER:-`apk search aria2 | sed -n "1s@aria2-\(.*\)@\1@p"`} curl bash jq findutils \
 && rm -rf /var/cache/apk/* /tmp/* \
 && sed -i "s@\(^root:.*\)/ash@\1/bash@" /etc/passwd

COPY --chmod=777 setup/ /

VOLUME [ "/downloads", "/config" ]

EXPOSE ${RPC_PORT:-6800} ${BT_PORT:-6888} ${DHT_PORT:-${BT_PORT:-6888}}/udp

ENTRYPOINT ["/setEnv.sh"]
