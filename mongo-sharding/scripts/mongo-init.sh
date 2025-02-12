#!/bin/bash

###
# 1. Инициализация сервера конфигурации
###

docker exec -it mongoConfigSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "mongoConfigSrv:27017" }
    ]
  }
);
exit();
EOF

###
# 2. Инициализация шарды 1
###

docker exec -it mongoShard1 mongosh --port 27018 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "mongoShard1:27018" }
      ]
    }
);
exit();
EOF

###
# 3. Инициализация шарды 2
###

docker exec -it mongoShard2 mongosh --port 27019 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 1, host : "mongoShard2:27019" },
      ]
    }
);
exit();
EOF

###
# 4. Инициализация роутера
###

docker exec -it mongosRouter mongosh --port 27020 <<EOF
sh.addShard( "shard1/mongoShard1:27018");
sh.addShard( "shard2/mongoShard1:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

