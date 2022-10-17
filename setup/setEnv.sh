#!/usr/bin/env bash

. /const.sh
LOGI "Checking..."
LOGI $(aria2c --version)

# http://c.biancheng.net/linux_tutorial/60/

# 创建用户组和用户
GRPNAME=aria2
if [ -z ${PGID} ]; then
  PGID=65533
  GRPNAME="nogroup"
fi
egrep "^([^:]*:){2}${PGID}:" /etc/group &> /dev/null && {
  # GRPNAME=`egrep "^([^:]*:){2}${PGID}:" /etc/group | sed "s@\([^:]*\):[^:]*:${PGID}:.*@\1@"`
  GRPNAME=`getent group ${PGID} | cut -d: -f1`
} || {
  [ ${PGID} -le 999 ] && {
    addgroup -g ${PGID} -S ${GRPNAME}
  } || {
    addgroup -g ${PGID} ${GRPNAME}
  }
}

USRNAME=aria2
if [ -z ${PUID} ]; then
  PUID=65534
  USRNAME="nobody"
fi
egrep "^([^:]*:){2}${PUID}:" /etc/passwd &> /dev/null && {
  # USRNAME=`egrep "^([^:]*:){2}${PUID}:" /etc/passwd | sed "s@\([^:]*\):[^:]*:${PUID}:.*@\1@"`
  USRNAME=`getent passwd ${PUID} | cut -d: -f1`
  adduser ${USRNAME} ${GRPNAME}
  # sed -i "s@\([^:]*:[^:]*:${PUID}:[^:]*:[^:]*:[^:]*:\).*@\1/bin/bash@" /etc/passwd
} || {
  [ ${PUID} -le 999 ] && {
    adduser -H -D -S -G ${GRPNAME} -s /bin/bash -u ${PUID} ${USRNAME}
  } || {
    adduser -H -D -G ${GRPNAME} -s /bin/bash -u ${PUID} ${USRNAME}
  }
}

# umask
if [ -z ${UMASK} ]; then
  if [ ${PUID} -gt 999 ] && [ ${GRPNAME} = ${USRNAME} ]; then
    UMASK=002
  elif [[ ${PUID} = 65534 || ${PGID} = 65533 ]]; then
    UMASK=000
  else
    UMASK=022
  fi
fi
umask ${UMASK}

# 时区
[[ -n ${TZ} ]] && {
  ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
  echo ${TZ} > /etc/timezone
}
LOGI "group=${GRPNAME}(${PGID}) user=${USRNAME}(${PUID}) umask=${UMASK} TZ=${TZ}"

mkdir -p ${DOWNLOAD_DIR}
# mkdir -p ${ARIA2_CONF_DIR}
mkdir -p ${SCRIPT_DIR}
# 修复权限
chown -R ${USRNAME}:${GRPNAME} ${ARIA2_CONF_DIR}
# if [ -w ${DOWNLOAD_DIR} ]; then LOGI "Download DIR writeable, not changing owner.";
# else chown -R ${USRNAME}:${GRPNAME} ${DOWNLOAD_DIR}; fi
chown -R ${USRNAME}:${GRPNAME} ${DOWNLOAD_DIR};
if [[ ${PUID} = 65534 || ${PGID} = 65533 ]]; then
  LOGW "Ignore permission settings."
  chmod -vR 777 ${ARIA2_CONF_DIR}
  chmod -vR 777 ${DOWNLOAD_DIR}
else
  # if [ -w ${DOWNLOAD_DIR} ]; then LOGI "Download DIR writeable, not modifying permission.";
  # else chmod -v u=rwx ${DOWNLOAD_DIR};fi
  chmod -v u=rwx ${DOWNLOAD_DIR};
  if [ -f "${ARIA2_CONF}" ]; then
    chmod -v 644 ${ARIA2_CONF_DIR}/*
    chmod -v 755 ${SCRIPT_DIR}
    chmod -v 744 ${SCRIPT_DIR}/*
  fi
fi

[[ "${FILE_ALLOCATION}" = "none" || "${FILE_ALLOCATION}" = "prealloc" || "${FILE_ALLOCATION}" = "trunc" || "${FILE_ALLOCATION}" = "falloc" ]] ||
  FILE_ALLOCATION="prealloc"
[[ "${UPDATE_TRACKERS:-true}" = "true" ]] && {
  rm -rf /etc/crontabs/root
  echo "0 * * * * bash ${SCRIPT_DIR}/tracker.sh ${ARIA2_CONF} RPC 2>&1 | tee ${ARIA2_CONF_DIR}/tracker.log" > /etc/crontabs/${USRNAME}
  crond
}

export GRPNAME USRNAME PUID PGID UMASK TZ

# 以用户权限运行脚本
su -p -s /bin/bash ${USRNAME} -c "/main.sh"
