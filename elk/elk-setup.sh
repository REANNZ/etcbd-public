#!/bin/bash

echo "Loading dashboards and visualizations..."
docker exec kibana /load_dashboards.sh
echo "...done"

