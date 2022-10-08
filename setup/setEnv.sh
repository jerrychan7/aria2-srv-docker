#!/bin/sh

. /utils.sh
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
} || {
  [ ${PUID} -le 999 ] && {
    adduser -H -D -S -G ${GRPNAME} -u ${PUID} ${USRNAME}
  } || {
    adduser -H -D -G ${GRPNAME} -u ${PUID} ${USRNAME}
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

mkdir -p /downloads
mkdir -p /config
# 修复权限
chown -R ${USRNAME}:${GRPNAME} /config
if [ -w /downloads ]; then LOGI "Download DIR writeable, not changing owner.";
else chown -R ${USRNAME}:${GRPNAME} /downloads; fi
if [[ ${PUID} = 65534 || ${PGID} = 65533 ]]; then
  LOGW "Ignore permission settings."
  chmod -vR 777 /config
  chmod -vR 777 /downloads
else
  if [ -w /downloads ]; then LOGI "Download DIR writeable, not modifying permission.";
  else chmod -v u=rwx /downloads;fi
  if [ -f "/config/aria2.conf" ]; then
    chmod -v 644 /config/*
    chmod -v 744 /config/*.sh
    chmod -v 744 /config/core
  fi
fi

[[ "${UPDATE_TRACKERS:-true}" = "true" ]] && {
  echo "0 * * * * bash /config/tracker.sh /config/aria2.conf RPC 2>&1 | tee /config/tracker.log" > /etc/crontabs/${USRNAME}
  crond
}

export GRPNAME USRNAME PUID PGID UMASK TZ

# 以用户权限运行脚本
su -p -s /bin/sh ${USRNAME} -c "/main.sh"
