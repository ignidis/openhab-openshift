#!/bin/bash
#
# docker build openhab image
# Usage:
#        [sudo] build.sh <openhab-version> <java-zulu-embedded-url> <nodejs-version> <registry> <registry-user> <registry-pwd> <project>
#
# Must run as superuser, either you are root or must sudo 
#
# Zulu 8 JDK for CENTOS
# JAVA_URL="https://cdn.azul.com/zulu/bin/zulu8.40.0.25-ca-jdk8.0.222-linux_x64.tar.gz"
#
#docker build --build-arg NAME="OPENHAB" --build-arg APP_ROOT="/opt" --build-arg OPENHAB_VERSION="$1" --build-arg JAVA_URL="$2" --build-arg NODE_VERSION="$3" --build-arg OPENHAB_SVC_NAME="openhab" --build-arg OPENHAB_SVC_UID="9001" -t openhab:"$1"-amd64-centos .

docker build --build-arg NAME="OPENHAB" --build-arg APP_ROOT="/opt" --build-arg OPENHAB_VERSION="$1" --build-arg JAVA_URL="$2" --build-arg NODE_VERSION="$3" --build-arg OPENHAB_SVC_NAME="openhab" --build-arg OPENHAB_SVC_UID="9001" --rm -t builder:ml-openhab-amd64-centos --file ./Builderfile . && \
docker run --rm -it -d --name builder-openhab-amd64-centos builder:ml-openhab-amd64-centos bash && \
docker export builder-openhab-amd64-centos | docker import - builder:openhab-amd64-centos && \
docker kill builder-openhab-amd64-centos && \
docker build --build-arg NAME="OPENHAB" --build-arg APP_ROOT="/opt" --build-arg OPENHAB_VERSION="$1" --build-arg JAVA_URL="$2" --build-arg NODE_VERSION="$3" --build-arg OPENHAB_SVC_NAME="openhab" --build-arg OPENHAB_SVC_UID="9001" --rm -t "$4"/"$7"/openhab:"$1"-amd64-centos . && \
docker rmi builder:ml-openhab-amd64-centos builder:openhab-amd64-centos && \
docker login -p "$6" -u "$5" "$4" && \
docker push "$4"/"$7"/openhab:"$1"-amd64-centos && \
docker rmi "$4"/"$7"/openhab:"$1"-amd64-centos
