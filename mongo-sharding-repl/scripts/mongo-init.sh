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

docker compose exec -T mongo_shard1-a mongosh --port 27018 <<EOF
rs.initiate({_id: "shard1", members: [{_id: 0, host: "mongo_shard1-a:27018"},{_id: 1, host: "mongo_shard1-b:27019"},{_id: 2, host: "mongo_shard1-c:27020"}]})
EOF

###
# 3. Инициализация шарды 2
###

docker compose exec -T mongo_shard2-a mongosh --port 27021 <<EOF
rs.initiate({_id: "shard2", members: [{_id: 0, host: "mongo_shard2-a:27021"},{_id: 1, host: "mongo_shard2-b:27022"},{_id: 2, host: "mongo_shard2-c:27023"}]})
EOF

sleep 10s
###
# 4. Инициализация роутера
###

docker compose exec -T mongo_router mongosh --port 27024 <<EOF
sh.addShard( "shard1/mongo_shard1-a:27018")
sh.addShard( "shard1/mongo_shard1-b:27019")
sh.addShard( "shard1/mongo_shard1-c:27020")
sh.addShard( "shard2/mongo_shard2-a:27021")
sh.addShard( "shard2/mongo_shard2-b:27022")
sh.addShard( "shard2/mongo_shard2-c:27023")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

read -p "Press enter to continue"