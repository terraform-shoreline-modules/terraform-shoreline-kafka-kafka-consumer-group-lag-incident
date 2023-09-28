
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Kafka Consumer Group Lag Incident
---

The Kafka Consumer Group Lag incident refers to a situation where the lag time for a Kafka consumer group exceeds the expected threshold. This delay can result in delayed or lost data processing, leading to service degradation or failure.

### Parameters
```shell
export BROKER_HOSTNAME_PORT="PLACEHOLDER"

export CONSUMER_GROUP_NAME="PLACEHOLDER"

export KAFKA_TOPIC="PLACEHOLDER"

export PATH_TO_KAFKA_BIN="PLACEHOLDER"

export ZOOKEEPER_HOST="PLACEHOLDER"

export NUMBER_OF_NEW_CONSUMERS="PLACEHOLDER"
```

## Debug

### Find out the brokers in the Kafka cluster
```shell
kafka-topics.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --list
```

### Check the status of Kafka brokers and zookeeper
```shell
systemctl status kafka zookeeper
```

### Check the consumer group status
```shell
kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --describe --group ${CONSUMER_GROUP_NAME}
```

### Check the partition lag for the consumer group
```shell
kafka-consumer-groups.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --describe --group ${CONSUMER_GROUP_NAME} | awk 'NR > 1 {print $1"\t"$6}'
```

### Check topics metadata to see if any topics are unbalanced
```shell
kafka-topics.sh --bootstrap-server ${BROKER_HOSTNAME_PORT} --describe
```

### Check the disk space usage on the Kafka brokers
```shell
df -h
```

### Check the network connectivity between the brokers and the consumer group
```shell
ping ${BROKER_HOSTNAME}
```

### Check the Zookeeper logs for any errors
```shell
tail -f /var/log/zookeeper/zookeeper.log
```

### Check the Kafka broker logs for any errors
```shell
tail -f /var/log/kafka/server.log
```

### One or more Kafka brokers in the cluster are down or experiencing high latency, causing the consumer group to fall behind in processing messages.
```shell
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


```

## Repair

### Increase the number of consumers to handle the load and reduce the lag.
```shell


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


```