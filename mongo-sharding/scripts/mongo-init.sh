#!/bin/bash

###
# 1. Инициализация сервера конфигурации
###

docker compose exec -T mongo_config mongosh --port 27017 <<EOF
rs.initiate({_id : "config_server",configsvr: true, members: [{ _id : 0, host : "mongo_config:27017" }]})
EOF

###
# 2. Инициализация шарды 1
###

docker compose exec -T mongo_shard1 mongosh --port 27018 <<EOF
rs.initiate({_id : "shard1",members: [{ _id : 0, host : "mongo_shard1:27018" }]})
EOF

###
# 3. Инициализация шарды 2
###

docker compose exec -T mongo_shard2 mongosh --port 27019 <<EOF
rs.initiate({_id : "shard2",members: [{ _id : 1, host : "mongo_shard2:27019" }]})
EOF

sleep 10s
###
# 4. Инициализация роутера
###

docker compose exec -T mongo_router mongosh --port 27020 <<EOF
sh.addShard( "shard1/mongo_shard1:27018")
sh.addShard( "shard2/mongo_shard2:27019")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

read -p "Press enter to continue"