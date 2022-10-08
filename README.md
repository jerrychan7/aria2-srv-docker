# docker-aria2-srv

一个运行在 Docker 中的 Aria2 服务端。

好多docker中的aria2都无法在第一代树莓派中运行（armv6l），特别是咱很想要的[P3TERX/Ara2-Pro-Docker](https://github.com/P3TERX/Aria2-Pro-Docker)，可是实际上是会无限重启。
咱提了issue[#99](https://github.com/P3TERX/Aria2-Pro-Docker/issues/99)，但不知什么时候能解决。
其核心[P2TERX/Aria2-Pro-Core](https://github.com/P3TERX/Aria2-Pro-Core)中对 armhf 的交叉编译无法在树莓派一代中运行，咱手动编译也老出现问题，遂放弃。

这个库的灵感来自：[xfqz86/docker-aria2-srv](https://github.com/xfqz86/docker-aria2-srv)，[SuperNG6/docker-aria2](https://github.com/SuperNG6/docker-aria2)

特征：

* [x] UID，GID包括nobody和nogroup
* [x] 合理的权限配置
* [x] BT和DTH端口开放
* [x] 默认开启DTH
* [x] IPv6 支持
* [x] 最优化配置文件（感谢[P3TERX/aria2.conf](https://github.com/P3TERX/aria2.conf)）
* [x] 默认上海时区（`Asia/Shanghai`）
* [x] 随机初始化token（可手动）
* [x] 自动更新tracker
* [ ] 在保存磁链为种子时更名
* [ ] 删除未完成任务时自动删除没下载完的文件
* [ ] 自动删除.aria2控制文件
* [ ] 回收站
* [ ] 检测重复任务
* [ ] 解除aria2的单服务器线程数最大值限制，参考[johngong/aria2](https://github.com/gshang2017/docker/tree/master/aria2)的镜像构建时编译。

## 快速开始

```console
$ git clone https://github.com/xfqz86/docker-aria2-srv.git
$ cd docker-aria2-srv
$ DOCKER_BUILDKIT=1 docker build -t aria2-srv .
$ docker run -d \
  --name aria2-srv \
  --restart unless-stopped \
  --network host -e IPV6_MODE=true \
  -v ~/downloads:/downloads -v ~/aria2-config:/config \
  -p 6800:6800 -p 6888:6888 -p 6888:6888/udp \
  aria2-srv
```

~~实际上是懒得发布到dockerhub中，因为咱坚信无敌的Aria2-Pro会修复无限重启的问题。~~

## 配置

| 环境参数 | 说明 | 缺省值 |
|---|---|---|
|`PUID`<br/>`PGID`|绑定UID和GID到容器。你可以使用非管理员用户来管理下载的文件。值为空时，`PUID=65534 (nobody) PGID=65533 (nogroup)`|`1000`<br/>`1000`|
|`UMASK`|aira2的umask设置，值为空时会根据`PUID`和`PGID`来判断。|`022`|
|`SECRET`|RPC密钥|随机的UUID|
|`RPC_PORT`|RPC监听的端口，对应配置文件中的 `rpc-listen-port`|`6800`|
|`BT_PORT`|BitTorrent监听端口，对应配置文件中的 `listen-port`|`6888`|
|`DHT_PORT`|DHT监听端口，对应配置文件中的 `dht-listen-port`|和`BT_PORT`一致|
|`IPV6_MODE`|是否开启Aria2的IPv6支持。（对应配置文件中的`disable-ipv6`和`enable-dht6`字段）。|`false`|
|`FILE_ALLOCATION`|文件预分配方式, 可选：`none`, `prealloc`, `trunc`, `falloc`。若出现错误提示`fallocate failed. cause：Operation not supported`则说明硬盘不支持此分配方式，需要更换。|`prealloc`|
|`TZ`|系统时区设置|`Asia/Shanghai`|
|`UPDATE_TRACKERS`|自动更新trackers|`true`|
|`CUSTOM_TRACKER_URL`|trackers的更新地址|`https://trackerslist.com/all_aria2.txt`|
|`WEAK_DEVICE`|是否降低配置（参考下面注意2）|`false`|

|卷路径|说明|
|---|---|
|`/downloads`|Aria2下载的位置|
|`/config`|Aria2配置文件位置|

|端口|说明|
|---|---|
|和`BT_PORT`环境参数一致|BitTorrent监听端口|
|`xx/udp`|`xx`和`DHT_PORT`环境参数一致，DHT监听端口|
|和`RPC_PORT`环境参数一致|RPC监听的端口|

### TODO (在不久的将来会尝试支持以下几个字段)

| 环境参数 | 说明 | 缺省值 |
|---|---|---|
|`RENAME_TORRENT`|重命名种子文件（`.torrent`后缀名文件）|`true`|
|`AUTO_DEL_CTRL_FILE`|下载完成自动删除控制文件(`.aria2`后缀名文件)|`true`|
|`AUTO_DEL_TORRENT`|下载完成自动删除种子文件(`.torrent`后缀名文件)|`false`|
|`AUTO_RM_EMPTY_DIR`|下载完成自动删除空目录|`false`|
|`ENABLE_DUP_TASKS`|是否允许重复任务|`false`|
|`RECYCLE_BIN`|是否开启回收站|`true`|
|`UNCOM_FILE_AUTO_RM`|是否在删除未完成任务时自动删除没下载完的文件|`true`|

## 注意

 1. aria2 运行配置文件保存在 `[配置文件目录]/aria2.conf` 。您可以根据实际需要进行设置，若文件不存在则会在启动容器时自动建立。具体配置项请参考：[aria2c OPTIONS](https://aria2.github.io/manual/en/html/aria2c.html#options)
 2. 由于树莓派一代性能太差，因此默认生成的配置文件里很多配置都调小了，特别是有关线程的，线程数太多会导致运行时RPC端口无响应。具体的调整如下表所示，如果宿主机性能好，可以适当调大。  
    |字段|调整值|原始值<br/>(来自[P3TERX/aria2.conf](https://github.com/P3TERX/aria2.conf))|
    |---|---|---|
    |`disk-cache`|`16M`|`64M`|
    |`no-file-allocation-limit`|`16M`|`64M`|
    |`max-connection-per-server`|`1`|`16`
    |`split`|`1`|`64`|
    |`min-split-size`|`16M`|`4M`|
    |`bt-max-peers`|`55`|`128`|
    |`bt-request-peer-speed-limit`|`2M`|`10M`|
    |`max-overall-upload-limit`|`1536K`|`2M`|
    |`max-concurrent-downloads`|`3`|`5`|
 3. 生成默认配置文件时会自动生成一个随机的 UUID 作为 RPC 密钥。可以使用 `grep -E '^rpc-secret=' [配置文件目录]/aria2.conf` 查询。为了方便用户，在运行日志中也有输出。
 4. 配置文件目录中 **包含重要的敏感信息**（如 RPC 密钥、代理服务器密码等），建议合理设置目录权限以避免泄密。
 5. 新建下载任务或设置配置文件中的下载目录时，请不要设置到 `/downloads` 目录外，否则将无法在宿主机实际下载目录中找到。
 6. 在较新的docker中`--network host`可以快速开启容器对IPv6的支持，在Windows、MacOS中则只能用`bridge`模式。`bridge`模式下开启容器对IPv6的支持请参考其他教程。

## 许可证

本存储库根据 [MIT License](http://opensource.org/licenses/MIT) 条款开源。
