#!/bin/sh

#docker run --rm -it -v$(dirname $0):/src -w /src alpine sh -c \
#docker run --rm -it -v$(dirname $0):/src -w /src ghcr.io/void-linux/void-glibc sh -c \
docker run --rm -it -v$(dirname $0):/src -w /src ubuntu:22.04 bash -c \
'
QT_VERSION_MAJOR=6.5
QT_VERSION=${QT_VERSION_MAJOR}.3

#https://askubuntu.com/questions/1175877/struggling-to-build-qt-due-to-missing-opengl-libraries
#apk add --no-cache build-base cmake ninja-build samurai python3 linux-headers wget tar xz
#xbps-install -Suy && xbps-install -y base-devel cmake ninja python3 wget tar
apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt install -y build-essential cmake python3 ninja-build tar wget xz-utils libdrm-dev libgles2-mesa-dev

[ ! -d "qt-everywhere-src-${QT_VERSION}" ] && wget -O - "https://download.qt.io/archive/qt/${QT_VERSION_MAJOR}/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz" | tar xJ

mkdir qt-everywhere-src-${QT_VERSION}/qt-build
cd qt-everywhere-src-${QT_VERSION}/qt-build
#../configure -no-opengl
#../configure -opensource -nomake tests
../configure
cmake --build . --parallel
#cmake --install .
echo cmake --install .
echo PATH="\$PATH:$(pwd)/qtbase/bin/qmake"
'
