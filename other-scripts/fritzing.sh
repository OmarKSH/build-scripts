#!/bin/sh

docker run --rm -it -v$(dirname $0):/src -w /src ubuntu:22.04 sh -c \
'
#export DEBIAN_FRONTEND=noninteractive

QT_VERSION_MAJOR=6.5
QT_VERSION=${QT_VERSION_MAJOR}.3

MAIN_DIR="$(pwd)"

apt update

DEBIAN_FRONTEND=noninteractive apt install -y git wget tar xz-utils gzip build-essential pkg-config cmake ninja-build libssl-dev libboost-dev #libgit2

#https://askubuntu.com/questions/1175877/struggling-to-build-qt-due-to-missing-opengl-libraries
#../configure -no-opengl
#../configure -opensource -nomake tests
[ ! -d "qt-everywhere-src-${QT_VERSION}" ] \
	&& wget -O - "https://download.qt.io/archive/qt/${QT_VERSION_MAJOR}/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz" | tar xJ

#apt update && DEBIAN_FRONTEND=noninteractive apt install -y libjpeg-dev libncurses5-dev libpng-dev libqt5serialport5-dev libqt5svg5-dev libudev-dev libz-dev python3-dev qttools5-dev-tools xvfb #qt5-default

mkdir qt-everywhere-src-${QT_VERSION}/qt-build \
	&& DEBIAN_FRONTEND=noninteractive apt install -y python3 libdrm-dev libgles2-mesa-dev libjpeg-dev libncurses5-dev libpng-dev libqt5serialport5-dev libqt5svg5-dev libudev-dev libz-dev python3-dev qttools5-dev-tools xvfb \
	&& cd qt-everywhere-src-${QT_VERSION}/qt-build \
	&& ../configure \
	&& cmake --build . --parallel

cd "$MAIN_DIR"

cd qt-everywhere-src-${QT_VERSION}/qt-build \
	&& cmake --install . \
	&& PATH="/usr/local/Qt-${QT_VERSION}/bin/:$(pwd)/qtbase/bin/qmake:$PATH"

cd "$MAIN_DIR"

#[ ! -d boost ] && wget -O - $(wget -O - https://api.github.com/repos/boostorg/boost/releases/latest | grep browser_download_url | grep -v .txt | grep tar.xz | grep -v cmake | tail -1 | cut -d" " -f8 | cut -d"\"" -f2) | tar xJ
#[ ! -d boost ] && git clone --depth=1 -bboost-1.86.0 https://github.com/boostorg/boost

#[ ! -d libgit2 ] && wget -O - $(wget -O - https://api.github.com/repos/libgit2/libgit2/releases/latest | grep tarball_url | cut -d"\"" -f4) | tar xz && mv libgit2-* libgit2 \
#[ ! -d libgit2 ] && git clone --depth=1 -bv1.8.1 https://github.com/libgit2/libgit2 \
#    && mkdir libgit2/build \
#    && cd libgit2/build \
#    && cmake -D BUILD_SHARED_LIBS=OFF .. \
#    && cmake --build . --parallel \

cd "$MAIN_DIR"

[ ! -d ngspice-42 ] \
	&& wget -O - https://sourceforge.net/projects/ngspice/files/ng-spice-rework/42/ngspice-42.tar.gz/download | tar xz \
	&& cd ngspice-42 && ln -s src/include

cd "$MAIN_DIR"

#[ ! -d "quazip-${QT_VERSION}-1.4" ] && wget -O - $(wget -O - https://api.github.com/repos/stachenov/quazip/releases/latest | grep tarball_url | cut -d"\"" -f4) | tar xz && mv stachenov-quazip-* quazip-${QT_VERSION}-1.4
[ ! -d "quazip-${QT_VERSION}-1.4" ] && git clone --depth=1 -bv1.4 https://github.com/stachenov/quazip quazip-${QT_VERSION}-1.4

[ ! -d fritzing-parts ] && git clone --depth=1 -b1.0.4  https://github.com/fritzing/fritzing-parts

[ ! -d fritzing-app ] && git clone --depth=1 -b1.0.3 https://github.com/fritzing/fritzing-app

mkdir fritzing-app/build

cd fritzing-app/build && qmake .. && make -j$(nproc) release

exec bash
'
