#!/bin/sh

#https://github.com/mingchen/docker-android-build-box
#docker run --rm -v `pwd`:/project android-sdk bash -c 'cd /project; ./gradlew build'
#docker run --rm -v `pwd`:/project saschpe/android-sdk:35-jdk23.0.2_7 bash -c 'cd /project; ./gradlew build'
docker run --rm -v `pwd`:/project alvrme/alpine-android:android-29-jdk21 bash -c 'cd /project; ./gradlew build'
