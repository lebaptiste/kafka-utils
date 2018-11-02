#! /bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

schema_registry_url=${SCHEMA_REGISTRY_URL:?}
topic_name=${1:?}
avro_file=${2:?}

# assuming we always target the lastest avro version
schema_value=$(cat "${avro_file}" | 
    python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)))" | 
    sed 's/"/\\"/g' ) #the full json schema must be escaped

curl -X POST -v --show-error -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{ "schema":"'"${schema_value}"'"}' \
     ${schema_registry_url%/}/subjects/${topic_name}-value/versions