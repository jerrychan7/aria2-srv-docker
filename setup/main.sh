#!/usr/bin/env bash

. /const.sh
. /p3terx_aria_conf_handler.sh

if [ ! -f "/config/aria2.conf" ]; then
  LOGI "Missing config files. Creating..."
  DOWNLOAD_P3TERX_PROFILE "aria2.conf script.conf core clean.sh delete.sh dht.dat dht6.dat LICENSE"
  # DOWNLOAD_P3TERX_PROFILE "aria2.conf core"
fi

[[ ! -f "/config/aria2.session" ]] && {
  rm -rf "/config/aria2.session"
  touch "/config/aria2.session"
}

if [[ "${UPDATE_TRACKERS:-true}" = "true" ]]; then
  [[ ! -f "${SCRIPT_DIR}/tracker.sh" ]] && DOWNLOAD_P3TERX_PROFILE "tracker.sh"
  ${SCRIPT_DIR}/tracker.sh ${ARIA2_CONF} | tee /config/tracker.log
fi

LOGI "Starting aria2 server..."
exec aria2c --conf-path=/config/aria2.conf
