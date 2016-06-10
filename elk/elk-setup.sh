#!/bin/bash

docker exec  kibana /import_dashboards.sh -l http://elasticsearch:9200

