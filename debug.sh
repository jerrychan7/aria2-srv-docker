
sudo docker stop my-aria2-srv
sudo docker rm -v my-aria2-srv
sudo docker rmi my-aria2-srv
sudo rm -rf ~/aria2-config-test/
# sudo rm -rf ~/aria2-config-test/tracker.sh
# sudo rm -rf ~/aria2-config-test/tracker.log
DOCKER_BUILDKIT=1 docker build -t my-aria2-srv .
  # --restart unless-stopped --memory-swap -1 --pids-limit -1 \
  # --network host \
sudo docker run -it --name my-aria2-srv \
  -e IPV6_MODE=true \
  -e PUID= -e PGID= -e UMASK= \
  -e CUSTOM_TRACKER_URL="https://cdn.staticaly.com/gh/XIU2/TrackersListCollection/master/all.txt" \
  -v ~/downloads:/downloads -v ~/aria2-config-test:/config \
  -e RPC_PORT=16800 -e BT_PORT=16888 -e DHT_PORT=16889 \
  -p 16800:16800 -p 16888:16888 -p 16888:16889/udp \
  my-aria2-srv
