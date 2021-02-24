# 1主2副

## 启动验证
```bash
$ dps up -d
Creating redis-master ... done
Creating redis-slave-2 ... done
Creating redis-slave-1 ... done

$ dps ps
    Name                   Command               State            Ports
--------------------------------------------------------------------------------
redis-master    docker-entrypoint.sh redis ...   Up      0.0.0.0:16379->6379/tcp
redis-slave-1   docker-entrypoint.sh redis ...   Up      0.0.0.0:16380->6379/tcp
redis-slave-2   docker-entrypoint.sh redis ...   Up      0.0.0.0:16381->6379/tcp


$ dps exec redis-master redis-cli info replication
# Replication
role:master
connected_slaves:2
slave0:ip=172.20.0.3,port=6379,state=online,offset=28,lag=1
slave1:ip=172.20.0.4,port=6379,state=online,offset=28,lag=1

$ dps exec redis-master redis-cli set a 1
OK
$ dps exec redis-slave-1 redis-cli get a
"1"
```

## 主从切换
```bash
#模拟掉线
$ dps stop redis-master
Stopping redis-master ... done
$ dps exec redis-slave-1 redis-cli info replication
# Replication
role:slave
master_host:redis-master
master_port:6379
master_link_status:down

#手动切换
$ dps exec redis-slave-1 redis-cli slaveof no one
OK
$ dps exec redis-slave-2 redis-cli slaveof redis-slave-1 6379
OK
$ dps exec redis-slave-1 redis-cli info replication
# Replication
role:master
connected_slaves:1
slave0:ip=172.20.0.3,port=6379,state=online,offset=260,lag=1

#测试主从
$ dps exec redis-slave-1 redis-cli set a 2
OK
$ dps exec redis-slave-2 redis-cli get a
"2"
```