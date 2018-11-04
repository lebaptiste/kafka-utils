#! /bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

kafka_rest_proxy=${KAFKA_REST_PROXY:?}
schema_registry_url=${SCHEMA_REGISTRY_URL:?}
topic_name=${1:?}
message_key=${2:?}
message_file=${3:?}

# assuming we always target the lastest avro version
schema=$(curl -X GET -s ${schema_registry_url%/}/subjects/${topic_name}-value/versions/latest |
    python3 -c "import sys, json; print(json.load(sys.stdin)['schema'])" | 
    sed 's/"/\\"/g' ) #the full json schema must be escaped

message_value=$(cat ${message_file} | \
    python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)))")

curl -X POST --show-error \
    -H "Content-Type: application/vnd.kafka.avro.v2+json" \
    -H "Accept: application/vnd.kafka.v2+json" \
    "${kafka_rest_proxy%/}/topics/${topic_name}" \
    --data-binary '{ "key_schema": "{ \"type\": \"string\" }", "value_schema":"'"${schema}"'", "records": [{"key" : "'"${message_key}"'", "value": '"${message_value}"'}]}'
echo