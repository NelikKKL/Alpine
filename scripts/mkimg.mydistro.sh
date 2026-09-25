#!/bin/sh
# scripts/mkimg.mydistro.sh
#
# Профиль для mkimage.sh (Alpine). Пакет ядра (linux-lts) подставляется
# автоматически движком через kernel_flavors — руками его в apks
# добавлять не нужно (это отдельный механизм, section_kernels).
#
# Сборка (из папки scripts/):
#   ./mkimage.sh --profile mydistro --outdir /work/out --arch x86_64 \
#       --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
#       --repository http://dl-cdn.alpinelinux.org/alpine/edge/community

profile_mydistro() {
	profile_standard
	profile_abbrev="mydistro"
	title="MyDistro"
	desc="Alpine + GNOME, live, без setup-alpine при загрузке."

	arch="x86_64"
	kernel_flavors="lts"
	kernel_cmdline="quiet"

	hostname="mydistro"

	# наш генератор /etc-оверлея — см. genapkovl-mydistro.sh рядом
	apkovl="genapkovl-mydistro.sh"

	apks="$apks
		grub grub-efi

		eudev eudev-hwids

		gcompat fuse

		pipewire pipewire-pulse pipewire-alsa wireplumber
		alsa-utils alsa-ucm-conf

		gnome gnome-shell gdm gnome-console gnome-text-editor
		gnome-control-center
		networkmanager networkmanager-tui
		dbus elogind polkit polkit-elogind
		xf86-video-vesa xf86-video-intel xf86-video-amdgpu xf86-video-nouveau
		mesa-dri-gallium mesa-dri-nouveau mesa-vulkan-swrast
		font-noto ttf-dejavu adwaita-icon-theme

		firefox
		nano
		git
		gimp

		sudo shadow
		"
}
