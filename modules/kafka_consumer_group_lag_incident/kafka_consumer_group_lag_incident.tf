resource "shoreline_notebook" "kafka_consumer_group_lag_incident" {
  name       = "kafka_consumer_group_lag_incident"
  data       = file("${path.module}/data/kafka_consumer_group_lag_incident.json")
  depends_on = [shoreline_action.invoke_kafka_health_check,shoreline_action.invoke_scale_kafka_consumers]
}

resource "shoreline_file" "kafka_health_check" {
  name             = "kafka_health_check"
  input_file       = "${path.module}/data/kafka_health_check.sh"
  md5              = filemd5("${path.module}/data/kafka_health_check.sh")
  description      = "One or more Kafka brokers in the cluster are down or experiencing high latency, causing the consumer group to fall behind in processing messages."
  destination_path = "/agent/scripts/kafka_health_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "scale_kafka_consumers" {
  name             = "scale_kafka_consumers"
  input_file       = "${path.module}/data/scale_kafka_consumers.sh"
  md5              = filemd5("${path.module}/data/scale_kafka_consumers.sh")
  description      = "Increase the number of consumers to handle the load and reduce the lag."
  destination_path = "/agent/scripts/scale_kafka_consumers.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_kafka_health_check" {
  name        = "invoke_kafka_health_check"
  description = "One or more Kafka brokers in the cluster are down or experiencing high latency, causing the consumer group to fall behind in processing messages."
  command     = "`chmod +x /agent/scripts/kafka_health_check.sh && /agent/scripts/kafka_health_check.sh`"
  params      = ["PATH_TO_KAFKA_BIN","KAFKA_TOPIC","CONSUMER_GROUP_NAME","ZOOKEEPER_HOST"]
  file_deps   = ["kafka_health_check"]
  enabled     = true
  depends_on  = [shoreline_file.kafka_health_check]
}

resource "shoreline_action" "invoke_scale_kafka_consumers" {
  name        = "invoke_scale_kafka_consumers"
  description = "Increase the number of consumers to handle the load and reduce the lag."
  command     = "`chmod +x /agent/scripts/scale_kafka_consumers.sh && /agent/scripts/scale_kafka_consumers.sh`"
  params      = ["BROKER_HOSTNAME_PORT","KAFKA_TOPIC","CONSUMER_GROUP_NAME","NUMBER_OF_NEW_CONSUMERS"]
  file_deps   = ["scale_kafka_consumers"]
  enabled     = true
  depends_on  = [shoreline_file.scale_kafka_consumers]
}

