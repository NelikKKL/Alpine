#!/bin/sh -e
# scripts/genapkovl-mydistro.sh
#
# Генерирует $HOSTNAME.apkovl.tar.gz — оверлей /etc, который
# распаковывается поверх initramfs при загрузке live-системы.
# Вызывается автоматически движком mkimage (build_apkovl в mkimg.base.sh),
# руками запускать не нужно.

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
gnome
gnome-shell
gdm
networkmanager
firefox
nano
git
gimp
fuse
gcompat
pipewire
pipewire-pulse
wireplumber
alsa-utils
gnome-control-center
EOF

makefile root:root 0644 "$tmp"/etc/motd <<EOF
MyDistro live — GNOME уже настроен, дополнительная настройка не требуется.
EOF

# сервисы, обязательные для загрузки live-образа (как в genapkovl-dhcp.sh)
rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add networking boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# наши сервисы: графика поднимается сама, setup-alpine не запускается
rc_add dbus default
rc_add networkmanager default
rc_add elogind default
rc_add polkit default
rc_add gdm default

tar -c -C "$tmp" etc | gzip -9n > "$HOSTNAME".apkovl.tar.gz
