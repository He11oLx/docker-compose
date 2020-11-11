#!/bin/bash
docker-compose down

mkdir conf
mkdir data

cat >./conf/mongo.conf<<EOF
systemLog:
    destination: file
    path: "/var/lib/mongo/mongodb.log"
    logAppend: true
processManagement:
    fork: false
net:
    bindIp: 0.0.0.0
    port: 27017
storage:
    engine: wiredTiger
    dbPath: /var/lib/mongo
replication:
    replSetName: "my_cluster"
EOF

cat >./conf/init.sh<<EXX
cat << EOF | mongo --host localhost:27017
rs.initiate({_id:"my_cluster",members:[{_id:0,    host:"localhost:27017"}]});
EOF
EXX

cat >./conf/add_user.sh<<EXX
cat << EOF | mongo --host localhost:27017
use    admin;
db.createUser(
     {
       user:"root",
       pwd:"root",
       roles:[{role:"userAdminAnyDatabase",db:"admin"}]
     }
  )
EOF
EXX

docker-compose up -d
sleep 5
docker-compose exec mongo bash /etc/mongo/init.sh
docker-compose exec mongo bash /etc/mongo/add_user.sh