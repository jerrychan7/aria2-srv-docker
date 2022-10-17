
# Credits: https://github.com/P3TERX/Docker-Aria2-Pro

# . /utils.sh

function LOG_DATE_HANDLER() {
  sed -i "s@date +\"%m/%d %H:%M:%S\"@date -u +\"%m/%d %T\"@" "${1}"
}

function SCRIPT_CONF_HANDLER() {
  sed -i "s@\(upload-log=\).*@\1${ARIA2_CONF_DIR}/upload.log@" "${SCRIPT_CONF}"
  sed -i "s@\(move-log=\).*@\1${ARIA2_CONF_DIR}/move.log@" "${SCRIPT_CONF}"
  sed -i "s@^\(dest-dir=\).*@\1${DOWNLOAD_DIR}/completed@" "${SCRIPT_CONF}"
}

function ARIA2_CONF_HANDLER() {
  sed -i "s@^\(listen-port=\).*@\1${BT_PORT:-6888}@" "${ARIA2_CONF}"
  sed -i "s@^\(dht-listen-port=\).*@\1${DHT_PORT:-${BT_PORT:-6888}}@" "${ARIA2_CONF}"
  sed -i "s@^\(rpc-listen-port=\).*@\1${RPC_PORT:-6800}@" "${ARIA2_CONF}"
  sed -i "s@^\(file-allocation=\).*@\1${FILE_ALLOCATION}@" "${ARIA2_CONF}"
  sed -i "s@^\(dir=\).*@\1${DOWNLOAD_DIR}@" "${ARIA2_CONF}"
  sed -i "s@/root/.aria2@${ARIA2_CONF_DIR}@" "${ARIA2_CONF}"
  sed -i "s@^\(seed-ratio=\).*@\1 1.1@" "${ARIA2_CONF}"
  sed -i "s@^\(seed-time=\).*@\1 1@" "${ARIA2_CONF}"
  sed -i "s@^\(on-download-stop=\).*@\1${SCRIPT_DIR}/delete.sh@" ${ARIA2_CONF}
  sed -i "s@^\(on-download-complete=\).*@\1${SCRIPT_DIR}/clean.sh@" "${ARIA2_CONF}"
  [[ "${IPV6_MODE}" = "true" ]] && {
    sed -i "s@^\(disable-ipv6=\).*@\1false@" "${ARIA2_CONF}"
    sed -i "s@^\(enable-dht6=\).*@\1true@" "${ARIA2_CONF}"
  } || {
    sed -i "s@^\(disable-ipv6=\).*@\1true@" "${ARIA2_CONF}"
    sed -i "s@^\(enable-dht6=\).*@\1false@" "${ARIA2_CONF}"
  }

  if [[ -z "${RPC_SECRET}" ]]; then
    LOGI "Generating RPC-Secret..."
    RPC_SECRET=`cat /proc/sys/kernel/random/uuid`
    sed -i "s@^\(rpc-secret=\).*@\1${RPC_SECRET}@" "${ARIA2_CONF}"
    LOGI "${RPC_SECRET}"
  fi

  [[ "${WEAK_DEVICE}" = "true" ]] && {
    sed -i "s@^\(max-connection-per-server=\).*@\1 2@" "${ARIA2_CONF}"
    sed -i "s@^\(split=\).*@\1 2@" "${ARIA2_CONF}"
    sed -i "s@^\(min-split-size=\).*@\1 64M@" "${ARIA2_CONF}"
    sed -i "s@^\(bt-max-peers=\).*@\1 55@" "${ARIA2_CONF}"
    sed -i "s@^\(bt-request-peer-speed-limit=\).*@\1 2M@" "${ARIA2_CONF}"
    sed -i "s@^\(max-overall-upload-limit=\).*@\1 1536K@" "${ARIA2_CONF}"
    sed -i "s@^\(max-concurrent-downloads=\).*@\1 3@" "${ARIA2_CONF}"
  }

  # 删除所有中文以及无用注释
  # [[ $TZ != "Asia/Shanghai" ]] && sed -i '11,$s/#.*//;/^$/d' "${ARIA2_CONF}"
}

function CORE_HANDLER() {
  local corePath=${1:-"${SCRIPT_DIR}/core"}
  LOG_DATE_HANDLER ${corePath}
  sed -i "s@\(ARIA2_CONF_DIR=\"\).*@\1${ARIA2_CONF_DIR}\"@" "${corePath}"
  chmod +x "${corePath}"
}

CURL_OPTIONS="-fsSL --connect-timeout 3 --max-time 3"
P3TERX_ARIA2_CONF_URLS="
https://p3terx.github.io/aria2.conf
https://aria2c.now.sh
https://cdn.jsdelivr.net/gh/P3TERX/aria2.conf
"
function DOWNLOAD_P3TERX_PROFILE() {
  local PROFILES=${1}
  local URLS=${2:-${P3TERX_ARIA2_CONF_URLS}}
  for PROFILE in ${PROFILES}; do
    [[ ${PROFILE} = *.sh || ${PROFILE} = core ]] && cd "${SCRIPT_DIR}" || cd "${ARIA2_CONF_DIR}"
    while [[ ! -f ${PROFILE} ]]; do
      rm -rf ${PROFILE}
      LOGI "Downloading '${PROFILE}'..."
      for URL in ${URLS}; do
        LOGI "- from ${URL}/${PROFILE}"
        curl -O ${CURL_OPTIONS} ${URL}/${PROFILE} && break
      done
      # 等待IO，再判断文件是否下载成功
      sleep 1
      if [[ -s ${PROFILE} ]]; then
        LOGI "'${PROFILE}' download completed!"
        [[ "${PROFILE}" = "aria2.conf" ]] && ARIA2_CONF_HANDLER
        [[ "${PROFILE}" = "script.conf" ]] && SCRIPT_CONF_HANDLER
        [[ "${PROFILE}" = "core" ]] && CORE_HANDLER
        [[ ${PROFILE} = *.sh || ${PROFILE} = core ]] && {
          LOG_DATE_HANDLER ${PROFILE}
          chmod +x ${PROFILE}
        }
      else
        LOGE "'${PROFILE}' download error, retry..."
        sleep 2
      fi
    done
  done
}
