#!/bin/bash

echo "Removing elasticsearch queue limit size..."
docker exec kibana curl -Ss -XPUT elasticsearch:9200/_cluster/settings -d '{ "persistent" : { "threadpool.search.queue_size" : -1 } }'
echo "...done"

echo "Loading dashboards and visualizations..."
docker exec kibana /load_dashboards.sh
echo "...done"

