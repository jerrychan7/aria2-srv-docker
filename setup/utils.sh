
_GREEN_FONT_PREFIX="\033[32m"
_RED_FONT_PREFIX="\033[31m"
_YELLOW_FONT_PREFIX="\033[1;33m"
_FONT_COLOR_SUFFIX="\033[0m"
INFO="[${_GREEN_FONT_PREFIX}INFO${_FONT_COLOR_SUFFIX}]"
WARN="[${_YELLOW_FONT_PREFIX}WARN${_FONT_COLOR_SUFFIX}]"
ERROR="[${_RED_FONT_PREFIX}ERROR${_FONT_COLOR_SUFFIX}]"
DATE_TIME() { date -u +"%m/%d %T"; }
LOG_WITHOUT_TIMESTAMP=
_LOG_TIME() { [[ -z "${LOG_WITHOUT_TIMESTAMP}" ]] && echo "$(DATE_TIME)" || echo ""; }
LOGI() { echo -e "$(_LOG_TIME) ${INFO} $*"; }
LOGW() { echo -e "$(_LOG_TIME) ${WARN} $*"; }
LOGE() { echo -e "$(_LOG_TIME) ${ERROR} $*"; }
CURL_OPTIONS="-fsSL --connect-timeout 3 --max-time 3"

P3TERX_ARIA2_CONF_URLS="
https://p3terx.github.io/aria2.conf
https://aria2c.now.sh
https://cdn.jsdelivr.net/gh/P3TERX/aria2.conf
"

function DOWNLOAD_PROFILE() {
  local PROFILES=${1}
  local URLS=${2:-${P3TERX_ARIA2_CONF_URLS}}
  cd /config/
  for PROFILE in ${PROFILES}; do
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
        [[ ${PROFILE} = *.sh || ${PROFILE} = core ]] && chmod +x ${PROFILE}
      else
        LOGE "'${PROFILE}' download error, retry..."
        sleep 2
      fi
    done
  done
}
