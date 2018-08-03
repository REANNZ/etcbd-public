#!/bin/bash

echo "Configuring elasticsearch NOT to create replicas..."
docker exec elasticsearch curl -Ss -HContent-Type:application/json -XPOST 'localhost:9200/_template/all' -d '{ "template": "*", "settings": { "number_of_replicas": 0 } }'

echo "Silencing JVM GC logs"
docker exec elasticsearch curl -Ss -HContent-Type:application/json -XPUT elasticsearch:9200/_cluster/settings -d '{ "persistent" : { "logger.org.elasticsearch.monitor.jvm.JvmGcMonitorService" : "WARN" } }'

if [ "$1" == "--force" ] ; then
    echo "Force upgrade - deleting .kibana index"
    docker exec elasticsearch curl -Ss -XDELETE http://127.0.0.1:9200/.kibana
fi

echo "Loading dashboards and visualizations..."
docker exec kibana /load_dashboards.sh
echo "...done"

