

#!/bin/bash



# Set the Kafka topic and consumer group name

KAFKA_TOPIC=${KAFKA_TOPIC}

CONSUMER_GROUP=${CONSUMER_GROUP_NAME}



# Set the number of consumers to add

NEW_CONSUMERS=${NUMBER_OF_NEW_CONSUMERS}



# Get the current number of consumers in the group

CURRENT_CONSUMERS=$(kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --describe --group $CONSUMER_GROUP | grep "CONSUMER_COUNT" | awk '{print $2}')



# Calculate the new number of consumers after adding the new ones

TOTAL_CONSUMERS=$((CURRENT_CONSUMERS+NEW_CONSUMERS))



# Scale the Kafka consumer group to the new number of consumers

kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --group $CONSUMER_GROUP --reset-offsets --to-earliest --all-topics --execute

kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --group $CONSUMER_GROUP --topic $KAFKA_TOPIC --reset-offsets --shift-by -1 --execute

kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --group $CONSUMER_GROUP --describe

kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --group $CONSUMER_GROUP --scale-out $TOTAL_CONSUMERS



# Verify that the number of consumers has been increased

kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --describe --group $CONSUMER_GROUP