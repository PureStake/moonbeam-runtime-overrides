#!/bin/bash

CLIENT_TAG=$1
CLIENT_IMAGE="purestake/moonbeam:$CLIENT_TAG"

mkdir -p target/release
docker create -ti --name dummy $CLIENT_IMAGE bash
docker cp dummy:/moonbeam/moonbeam target/release/moonbeam
docker rm -f dummy
