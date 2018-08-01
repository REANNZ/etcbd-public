#!/bin/bash

# Upgrading to ElasitSearch 6

# Setup cleanup function
function cleanup() {
    echo "Cleaning up..."
    if [ -n "$INDECES_FILE" -o -n "$RESULTS_FILE" ] ; then
	rm $INDECES_FILE $RESULTS_FILE
	INDECES_FILE=""
	RESULTS_FILE=""
    fi
    if [ -n "$RUNNING_CONTAINERS" ] ; then
	echo "Stopping containers $RUNNING_CONTAINERS"
        docker stop $RUNNING_CONTAINERS
	RUNNING_CONTAINERS=""
    fi
}

INDECES_FILE=""
RESULTS_FILE=""
RUNNING_CONTAINERS=""


trap "cleanup; exit 1" ERR INT TERM
set -e

function fail() {
    MSG="$*"
    echo "ERROR: $MSG"
    exit 1
}

# some ancillary functions
function wait_for_es() {
    CONTAINER="$1"
    RESULTS_FILE=$( mktemp )

    # Wait for ElasticSearch container to start
    echo "Waiting for ElasticSearch container '$CONTAINER' to start"
    while true ; do
        if docker exec $CONTAINER curl -Ss 'localhost:9200/_cluster/health?pretty' > $RESULTS_FILE ; then
            if grep -q '"status"' $RESULTS_FILE && grep '"status"' $RESULTS_FILE | grep -q -v '"status" *: *"red"' ; then
		# Ready: responding with a status and status is not red.
                break
            else
	        echo "$CONTAINER is still initializing: $( grep active_shards_percent_as_number "$RESULTS_FILE" )"
            fi
	fi
        sleep 10; 
    done
    rm $RESULTS_FILE
    RESULTS_FILE=
    echo "Container $CONTAINER is running..."
}

ES2_DATA_VOLUME=elk_elasticsearch-data
ES6_DATA_VOLUME=elk_elasticsearch-data-6

cat <<-EOF
	This script upgrades an Elasticsearch 2.x cluster to 6.x
	It does that by creating a new volume $ES6_DATA_VOLUME
	And reindexing all data onto the new volume.
	The pre-requisites for this upgrade are:
	* New volume $ES6_DATA_VOLUME has not been created yet.
	* Old ELK container has been stopped and removed.
	* Old volume $ES_2_DATA_VOLUME exists.
	Checking these now...

EOF

if docker volume inspect $ES6_DATA_VOLUME > /dev/null 2>&1 ; then
    echo "Docker volume $ES6_DATA_VOLUME already exists"
    echo "If this has been created accidentally and you want to start from scratch,"
    echo "delete the volume with:"
    echo "    docker volume rm elk_elasticsearch-data-6"
    fail "Docker volume $ES6_DATA_VOLUME already exists"
elif docker container inspect elasticsearch > /dev/null 2>&1 ; then
    echo "Docker container elasticsearch still exists"
    echo "If you are ready to start your migration now, stop and remove your old containers with:"
    echo "    docker-compose stop && docker-compose rm -f -v"
    fail "Docker container elasticsearch still exists"
elif ! docker volume inspect $ES2_DATA_VOLUME > /dev/null 2>&1 ; then
    fail "Docker volume $ES2_DATA_VOLUME does not exists"
fi

echo "Checks successfully passed.\n"

# To upgrade from ElasticSearch 2.x to 6.x, we need to reindex all documents from an old server to a new one
# Start up two separate containers:

# ?? OR KEEP old container running ??
ELASTICSEARCH_6_VERSION=6.3.2

# MAYBE run old container
ES_OLD="es-old"
# Run old container
echo "Starting ElasticSearch container $ES_OLD"
docker run -d --name $ES_OLD --rm -e ES_JAVA_OPTS='-Xms4096m -Xmx4096m' -v $ES2_DATA_VOLUME:/usr/share/elasticsearch/data elasticsearch:2
RUNNING_CONTAINERS="$RUNNING_CONTAINERS $ES_OLD"
wait_for_es $ES_OLD

ES_NEW="es6-conv"
# Run new container
echo "Starting ElasticSearch container $ES_NEW"
docker run -d --link $ES_OLD:$ES_OLD --name $ES_NEW --rm -e ES_JAVA_OPTS='-Xms4096m -Xmx4096m' -e reindex.remote.whitelist=$ES_OLD:9200 -v $ES6_DATA_VOLUME:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch-oss:$ELASTICSEARCH_6_VERSION
RUNNING_CONTAINERS="$RUNNING_CONTAINERS $ES_NEW"
wait_for_es $ES_NEW

INDECES_FILE=$( mktemp )

# Get list of indeces from OLD elasticsearch - and skip .kibana index
docker exec $ES_OLD curl -Ss http://localhost:9200/_cat/shards | \
    cut -d ' ' -f 1 | sort -u | grep -v '^.kibana$' > $INDECES_FILE

echo "Configuring NEW elasticsearch NOT to create replicas..."
docker exec $ES_NEW curl -Ss -HContent-Type:application/json -XPOST 'localhost:9200/_template/all' -d '{ "template": "*", "settings": { "number_of_replicas": 0 } }'

FAILED_INDECES=""
RESULTS_FILE=$( mktemp )
# reindex all indexes
while read INDEX ; do
    echo "Reindexing $INDEX"
    docker exec $ES_NEW curl -Ss -HContent-Type:application/json -XPOST 'localhost:9200/_reindex?pretty&refresh' -d'{
    "source": {
      "remote": {
        "host": "http://'$ES_OLD':9200"
      },
      "index": "'$INDEX'"
    },
    "dest": {
      "index": "'$INDEX'"
    }
  }' > $RESULTS_FILE
  # TODO: check results
  if grep '"error"' $RESULTS_FILE ; then
      echo "WARNING: reindex for $INDEX returned an error - please check the output below:"
      cat $RESULTS_FILE
      FAILED_INDECES="$FAILED_INDECES $INDEX"
  fi
done < $INDECES_FILE

echo "Reindexing complete, cleaning up"

cleanup

if [ -n "$FAILED_INDECES" ] ; then
    echo "WARNING: reindex failed for the following indexes: $FAILED_INDECES"
    echo "Please check the results carefully."
else
    echo "Elasticsearch data have been successfully migrated to volume $ES6_DATA_VOLUME"
    echo "You can now proceed with the next step of the upgrade."
fi
exit

