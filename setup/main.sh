
. /utils.sh

if [ ! -f "/config/aria2.conf" ]; then
  LOGI "Missing config files. Creating..."
  DOWNLOAD_PROFILE "aria2.conf script.conf core delete.sh dht.dat dht6.dat LICENSE"
  # DOWNLOAD_PROFILE "aria2.conf core"

  sed -i "s@^\(listen-port=\).*@\1${BT_PORT:-6888}@" /config/aria2.conf
  sed -i "s@^\(dht-listen-port=\).*@\1${DHT_PORT:-${BT_PORT:-6888}}@" /config/aria2.conf
  sed -i "s@^\(rpc-listen-port=\).*@\1${RPC_PORT:-6800}@" /config/aria2.conf
  [[ "${FILE_ALLOCATION}" = "none" || "${FILE_ALLOCATION}" = "prealloc" || "${FILE_ALLOCATION}" = "trunc" || "${FILE_ALLOCATION}" = "falloc" ]] && {
    sed -i "s@^\(file-allocation=\).*@\1${FILE_ALLOCATION}@" /config/aria2.conf
  } || {
    sed -i "s@^\(file-allocation=\).*@\1prealloc@" /config/aria2.conf
  }
  sed -i "s@^\(dir=\).*@\1/downloads@" /config/aria2.conf
  sed -i "s@/root/.aria2@/config@" /config/aria2.conf
  sed -i "s@^\(seed-ratio=\).*@\1 1.1@" /config/aria2.conf
  sed -i "s@^\(seed-time=\).*@\1 1@" /config/aria2.conf
  [[ "${IPV6_MODE}" = "true" ]] && {
    sed -i "s@^\(disable-ipv6=\).*@\1false@" /config/aria2.conf
    sed -i "s@^\(enable-dht6=\).*@\1true@" /config/aria2.conf
  } || {
    sed -i "s@^\(disable-ipv6=\).*@\1true@" /config/aria2.conf
    sed -i "s@^\(enable-dht6=\).*@\1false@" /config/aria2.conf
  }

  if [[ -z "${SECRET}" ]]; then
    LOGI "Generating RPC-Secret..."
    SECRET=`cat /proc/sys/kernel/random/uuid`
    sed -i "s@^\(rpc-secret=\).*@\1${SECRET}@" /config/aria2.conf
    LOGI "${SECRET}"
  fi

  [[ "${WEAK_DEVICE}" = "true" ]] && {
    sed -i "s@^\(disk-cache=\).*@\1 16M@" /config/aria2.conf
    sed -i "s@^\(no-file-allocation-limit=\).*@\1 16M@" /config/aria2.conf
    sed -i "s@^\(max-connection-per-server=\).*@\1 1@" /config/aria2.conf
    sed -i "s@^\(split=\).*@\1 1@" /config/aria2.conf
    sed -i "s@^\(min-split-size=\).*@\1 16M@" /config/aria2.conf
    sed -i "s@^\(bt-max-peers=\).*@\1 55@" /config/aria2.conf
    sed -i "s@^\(bt-request-peer-speed-limit=\).*@\1 2M@" /config/aria2.conf
    sed -i "s@^\(max-overall-upload-limit=\).*@\1 1536K@" /config/aria2.conf
    sed -i "s@^\(max-concurrent-downloads=\).*@\1 3@" /config/aria2.conf
  }
fi

[[ ! -f "/config/aria2.session" ]] && {
  rm -rf "/config/aria2.session"
  touch "/config/aria2.session"
}

if [[ "${UPDATE_TRACKERS:-true}" = "true" ]]; then
  [[ ! -f "/config/tracker.sh" ]] && DOWNLOAD_PROFILE "tracker.sh"
  sed -i "s@date +\"%m/%d %H:%M:%S\"@date -u +\"%m/%d %T\"@" /config/tracker.sh
  chmod +x /config/tracker.sh
  bash /config/tracker.sh /config/aria2.conf | tee /config/tracker.log
fi

LOGI "Starting aria2 server..."
exec aria2c --conf-path=/config/aria2.conf
