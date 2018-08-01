#!/bin/bash

echo "Configuring elasticsearch NOT to create replicas..."
docker exec elasticsearch curl -Ss -HContent-Type:application/json -XPOST 'localhost:9200/_template/all' -d '{ "template": "*", "settings": { "number_of_replicas": 0 } }'

echo "Loading dashboards and visualizations..."
docker exec kibana /load_dashboards.sh
echo "...done"

