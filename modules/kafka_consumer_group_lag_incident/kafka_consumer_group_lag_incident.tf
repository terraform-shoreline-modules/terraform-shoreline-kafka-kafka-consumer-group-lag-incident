resource "shoreline_notebook" "kafka_consumer_group_lag_incident" {
  name       = "kafka_consumer_group_lag_incident"
  data       = file("${path.module}/data/kafka_consumer_group_lag_incident.json")
  depends_on = [shoreline_action.invoke_zk_kafka_lag_check,shoreline_action.invoke_kafka_scale_consumers]
}

resource "shoreline_file" "zk_kafka_lag_check" {
  name             = "zk_kafka_lag_check"
  input_file       = "${path.module}/data/zk_kafka_lag_check.sh"
  md5              = filemd5("${path.module}/data/zk_kafka_lag_check.sh")
  description      = "One or more Kafka brokers in the cluster are down or experiencing high latency, causing the consumer group to fall behind in processing messages."
  destination_path = "/agent/scripts/zk_kafka_lag_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "kafka_scale_consumers" {
  name             = "kafka_scale_consumers"
  input_file       = "${path.module}/data/kafka_scale_consumers.sh"
  md5              = filemd5("${path.module}/data/kafka_scale_consumers.sh")
  description      = "Increase the number of consumers to handle the load and reduce the lag."
  destination_path = "/agent/scripts/kafka_scale_consumers.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_zk_kafka_lag_check" {
  name        = "invoke_zk_kafka_lag_check"
  description = "One or more Kafka brokers in the cluster are down or experiencing high latency, causing the consumer group to fall behind in processing messages."
  command     = "`chmod +x /agent/scripts/zk_kafka_lag_check.sh && /agent/scripts/zk_kafka_lag_check.sh`"
  params      = ["CONSUMER_GROUP_NAME","ZOOKEEPER_HOST","KAFKA_TOPIC","PATH_TO_KAFKA_BIN"]
  file_deps   = ["zk_kafka_lag_check"]
  enabled     = true
  depends_on  = [shoreline_file.zk_kafka_lag_check]
}

resource "shoreline_action" "invoke_kafka_scale_consumers" {
  name        = "invoke_kafka_scale_consumers"
  description = "Increase the number of consumers to handle the load and reduce the lag."
  command     = "`chmod +x /agent/scripts/kafka_scale_consumers.sh && /agent/scripts/kafka_scale_consumers.sh`"
  params      = ["CONSUMER_GROUP_NAME","NUMBER_OF_NEW_CONSUMERS","KAFKA_TOPIC","BROKER_HOSTNAME_PORT"]
  file_deps   = ["kafka_scale_consumers"]
  enabled     = true
  depends_on  = [shoreline_file.kafka_scale_consumers]
}

