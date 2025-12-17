#!/bin/sh

#set -e

select_from_list() {
	[ "$FZF" != '0' ] && [ -x "$(command -v fzf)" ] && { fzf "$@" <&0; return $?; } \
	|| { local line i=0 REPLY
	{ [ ! -t 0 ] && while IFS= read -r line; do [ -z "$line" ] && continue; echo "$i) $line" >/dev/tty; eval "local line$i=\"$line\""; i=$((i+1)); done; true; }
	# { while IFS= read -r line; do [ -z "$line" ] && continue; echo "$i) $line" >/dev/tty; eval "local line$i=\"$line\""; i=$((i+1)); done <<- EOF
	# $(for i in "$@"; do echo "$i"; done)
	# EOF
	# }
	echo -n "Enter choice number: " >/dev/tty && read -r REPLY </dev/tty && eval "echo -n \"\${line$REPLY}\"" && echo >/dev/tty; }
}

chroot() {
	CHROOT_DIR="$PWD"

	sudo umount -Rf "$CHROOT_DIR"/* 2>/dev/null

	sudo mount -t proc proc proc \
	        && sudo mount -t sysfs sys sys \
	        && sudo mount -t devtmpfs udev dev \
	        && sudo mount -t devpts devpts dev/pts

	sudo chroot . /bin/sh -c "r=\"\$(cat /etc/resolv.conf 2>/dev/null)\"; [ -z \"\$r\" ] && echo 'nameserver 1.1.1.1' > /etc/resolv.conf; chmod 777 /tmp; $@"

	cleanup
}

cleanup() { [ -d "$CHROOT_DIR" ] && sudo umount -Rf "$CHROOT_DIR"/* 2>/dev/null; [ -d "$_PWD" ] && cd "$_PWD"; }
trap 'cleanup' EXIT QUIT TERM
trap 'cleanup; exit' INT

_PWD="$PWD"
cd "${0%/*}"

mkdir scripts 2>/dev/null
SCRIPT=scripts/"${1:-$(ls scripts | select_from_list)}"

. "$SCRIPT"

[ "${#BUILD_CMD}" -eq 0 ] && echo "No build command, launching dev environment!"

COMMAND=$(cat <<- EOF
set -a # export all variables

# Make the build script variables available inside the launched environment
$([ -f "$SCRIPT" ] && cat "$SCRIPT")

trap 'echo "Interrupting flow"; exec sh' INT
trap 'echo "Error! dropping to shell"; exec sh' ERR

if type apt >/dev/null 2>/dev/null; then
	export DEBIAN_FRONTEND=noninteractive
	apt update && apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt install -y build-essential pkgconf automake autoconf
elif type xbps-install 2>/dev/null >/dev/null; then
	xbps-install -Suy && xbps-install -y base-devel
elif type apk >/dev/null 2>/dev/null; then
#Note that tar version of busybox won't work with packelf, you need to install gnu tar
	apk add --no-cache build-base pkgconf automake autoconf
fi

[ ${#BUILD_CMD} -eq 0 ] && { exec sh; exit 0; }

$PKG_CMD

[ -e "$TARGET_DIR" -a ! -d "$TARGET_DIR" ] && echo "$TARGET_DIR already exists and is not a directory" && exit 1 #&& TARGET_DIR="${TARGET_DIR}.$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)"
[ ! -d "$TARGET_DIR" ] && { $DOWNLOAD_CMD; }
[ ! -d "$TARGET_DIR" ] && { echo 'Failed to download files'; exit 1; }
cd "$TARGET_DIR"

chown -R $(id -u):$(id -g) .

git config --global --add safe.directory "\$PWD" 2>/dev/null || true

$BUILD_CMD

strip $TARGET || true

[ ! -d packelf ] && [ ! -d ../packelf ] && { git clone --depth=1 https://github.com/OmarKSH/packelf packelf 2>/dev/null || true; }
PATH=\$PATH:packelf:../packelf
for f in $TARGET; do { packelf.sh \$PWD/\$f \$f.blob 2>/dev/null && chmod +x \$f.blob; } || true; done

upx --lzma $TARGET || true

#read -n5 -r SUFFIX </dev/urandom && SUFFIX=`echo \$SUFFIX | base64`
SUFFIX=\$(mktemp -u) && SUFFIX=\${SUFFIX#*.}
TARGETS=
for f in $TARGET; do ln -f \$f \$f.\$SUFFIX; TARGETS="\$TARGETS \$f.\$SUFFIX"; done
$CLEANUP_CMD
for f in \$TARGETS; do ln -f "\$f" "\${f%.*}" && rm -f "\$f"; done

chown -R $(id -u):$(id -g) .

exit 0
EOF
)

mkdir chroots 2>/dev/null
#RUNTIME="${2:-$(ls chroots | select_from_list)}"
RUNTIME="${2:-$(find chroots -maxdepth 1 \( \( -type d ! -path chroots \) -o \( -type f -name '*.tar.gz' \) \) -exec basename {} \; | select_from_list)}"

if [ -z "$RUNTIME" -o "$RUNTIME" = 'docker' ]; then
	echo "Using docker!"

	docker kill -9 build-base 2>/dev/null
	docker rm build-base 2>/dev/null
	docker run --name build-base --rm -it -v"$_PWD":/src -w/src ${DOCKER_IMG:-alpine:latest} sh -c "$COMMAND"

	if [ -d "$_PWD/$TARGET_DIR" -a -n "$TARGET_DIR" ]; then
		for f in $TARGET; do #if one of the targets have the same name as the directory
			[ "$(basename "$TARGET_DIR")" != "$(basename "$f")" ] && continue
			NEW_TARGET_DIR="${TARGET_DIR}.src"
			[ -e "$_PWD/$NEW_TARGET_DIR" ] && NEW_TARGET_DIR="${NEW_TARGET_DIR}.$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)"
			mv "$_PWD/$TARGET_DIR" "$_PWD/$NEW_TARGET_DIR";
			TARGET_DIR="$NEW_TARGET_DIR"
			break
		done

		OLD_PWD="$PWD"; cd "$_PWD/$TARGET_DIR"; for f in $TARGET; do [ -e "$_PWD/$f" ] && mv -i "$f" "$_PWD/${f##*/}.$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)" || mv -n "$f" "$_PWD"; done; cd "$OLD_PWD"

		echo -n "Delete source directory? (y/N): " && read -r REPLY && { [ "$REPLY" = 'y' ] || [ "$REPLY" = 'Y' ]; } && echo "Deleting $TARGET_DIR" && sudo rm -rf "$_PWD/$TARGET_DIR"
	fi
else
	RUNTIME="chroots/$RUNTIME"

	[ -f "$RUNTIME" ] && { mkdir "$RUNTIME"_chroot 2>/dev/null && echo "extracting $RUNTIME" && tar xaf "$RUNTIME" -C "$RUNTIME"_chroot; RUNTIME="$RUNTIME"_chroot; }

	if [ -d "$RUNTIME" ]; then
		OLD_PWD="$PWD"; cd "$RUNTIME" && chroot "$COMMAND"; cd "$OLD_PWD"
		#OLD_PWD="$PWD"; mkdir -p "out/$(basename "$RUNTIME")" 2>/dev/null; cd "$RUNTIME/$TARGET_DIR"; mv "$TARGET" "$OLD_PWD/out/$(basename "$RUNTIME")"; cd "$OLD_PWD"
		OLD_PWD="$PWD"; cd "$RUNTIME/$TARGET_DIR"; for f in $TARGET; do [ -e "$_PWD/$f" ] && mv -i "$f" "$_PWD/${f##*/}.$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)" || mv -n "$f" "$_PWD"; done; cd "$OLD_PWD"
		if grep -q "$RUNTIME" /proc/mounts; then
			echo "Couldn't fully umount $RUNTIME"
		elif [ -d "$RUNTIME" ]; then
			echo -n "Delete ${RUNTIME}? (y/N): " && read -r REPLY && { [ "$REPLY" = 'y' ] || [ "$REPLY" = 'Y' ]; } && echo "Deleting $RUNTIME" && sudo rm -rf "$RUNTIME"
		fi
	fi
fi
