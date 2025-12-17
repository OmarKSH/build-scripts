#!/bin/sh

#https://github.com/mingchen/docker-android-build-box
docker run --rm -v `pwd`:/project android-sdk bash -c 'cd /project; ./gradlew build'
