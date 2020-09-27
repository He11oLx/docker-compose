#!/bin/bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 1 > /proc/sys/vm/overcommit_memory

PORTS=(6379 6380 6381)

mkdir -p ./conf
for port in ${PORTS[@]};
do
  mkdir -p ./data/$port;
  cat >./conf/redis-$port.conf<<EOF
bind 0.0.0.0
port $port
cluster-enabled yes
dir /data/$port/
cluster-config-file /data/$port/nodes.conf
cluster-node-timeout 5000
appendonly yes
EOF
done

docker-compose up -d
docker-compose ps


cat >./conf/cluster-init.conf<<EOF
ip1=\$(hostname -i)
redis-cli --cluster create --cluster-replicas 0 \$ip1:6379 redis-cluster-6380:6380 redis-cluster-6381:6381 --cluster-yes
EOF
docker-compose exec  redis-cluster-6379 /bin/sh /conf/cluster-init.conf

# 下面这种，$ip1:6379 有空格，会报错
#ip1=$(docker-compose exec  redis-cluster-6379  hostname -i)
#docker-compose exec  redis-cluster-6379 /bin/sh  -c "redis-cli --cluster create --cluster-replicas 0 $ip1:6379 redis-cluster-6380:6380 redis-cluster-6381:6381 --cluster-yes"

docker-compose exec  redis-cluster-6379  redis-cli cluster info