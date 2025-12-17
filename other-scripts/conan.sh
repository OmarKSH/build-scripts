docker run --rm -it -v$(dirname $0)/src:/src -v$HOME/conan2:/root/.conan2 -v$HOME/.bashrc:/root/.bashrc:ro -v$HOME/.bash_aliases:/root/.bash_aliases:ro ubuntu:22.04 bash -c \
'
apt update && apt install -y bash-completion vim && source /etc/bash_completion
apt install -y build-essential python3 python3-pip cmake ninja-build pkg-config git wget libssl-dev libboost-dev #libqt6core5compat6-dev
#pip install conan
#cd /src/fritzing-app && \
# && conan install .. --build=missing -c tools.system.package_manager:mode=install
exec bash
'
