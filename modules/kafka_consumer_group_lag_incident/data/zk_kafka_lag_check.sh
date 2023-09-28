bash

#!/bin/bash



# Set variables

ZK_HOST=${ZOOKEEPER_HOST}

KAFKA_BIN=${PATH_TO_KAFKA_BIN}

KAFKA_TOPIC=${KAFKA_TOPIC}

CONSUMER_GROUP=${CONSUMER_GROUP_NAME}



# Check zookeeper status

zk_status=$(echo ruok | nc "$ZK_HOST" 2181)

if [ "$zk_status" != "imok" ]; then

  echo "Zookeeper is not running."

  exit 1

fi



# Check Kafka brokers status

broker_list=$("$KAFKA_BIN"/zookeeper-shell.sh "$ZK_HOST":2181 <<< "ls /brokers/ids" | tail -n 1 | tr -d '[]' | tr ',' '\n')

for broker in $broker_list; do

  broker_status=$("$KAFKA_BIN"/kafka-broker-api-versions.sh --bootstrap-server "$ZK_HOST":9092 --broker-id "$broker" | grep -c "Metadata response received")

  if [ "$broker_status" -eq 0 ]; then

    echo "Broker $broker is not running or experiencing high latency."

    exit 1

  fi

done



# Check consumer group lag

consumer_group_lag=$("$KAFKA_BIN"/kafka-consumer-groups.sh --bootstrap-server "$ZK_HOST":9092 --describe --group "$CONSUMER_GROUP" | awk 'BEGIN {sum=0} {sum+=$3} END {print sum}')

if [ "$consumer_group_lag" -gt 0 ]; then

  echo "Consumer group $CONSUMER_GROUP is falling behind in processing messages. Total lag is $consumer_group_lag."

  exit 1

fi



echo "No issues found."

exit 0