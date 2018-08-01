#!/bin/bash

echo "Repair an elasticsearch node: reassign all unallocated primary shards to this node."

if [ $# -ne 1 ] || ! docker inspect -- "$1" > /dev/null ; then
   echo "Usage: $0 container-name"
   exit 1
fi

ES="$1"

SHARDS_FILE=$( mktemp )
echo "Inspecting $ES..."
docker exec $ES curl -Ss http://localhost:9200/_cat/shards | grep -v STARTED | grep -v ' r' > $SHARDS_FILE

if [ -s "$SHARDS_FILE" ] ; then
    echo "Node $ES has $( wc -l $SHARDS_FILE ) unallocated shards, repairing..."
    LOG_FILE="repair-$$.log"
    echo "Logging into $LOG_FILE"

    # Get node name: credits:
    # https://docs.docker.com/engine/reference/commandline/inspect/#get-an-instances-ip-address
    NODE="$( docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ES )"

    cat $SHARDS_FILE | cut -d ' ' -f 1,2 | while read INDEX SHARD ; do
	echo $INDEX $SHARD | tee -a $LOG_FILE
	docker exec $ES curl -Ss -XPOST 'localhost:9200/_cluster/reroute?pretty' -d '{
	    "commands" : [ {
		  "allocate" : {
		      "index" : "'$INDEX'", 
		      "shard" : '$SHARD', 
		      "node" : "'$NODE'", 
		      "allow_primary" : true
		  }
		}
	    ]
	}' >> $LOG_FILE
	sleep 10
    done
    echo "All done - checking cluster health:" | tee -a $LOG_FILE
    docker exec $ES curl -Ss http://localhost:9200/_cluster/health?pretty | tee -a $LOG_FILE

else
    echo "Node $ES appears to be healthy - no unallocated primary shards found."
fi
rm $SHARDS_FILE

