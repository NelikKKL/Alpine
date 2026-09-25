# MyDistro — Alpine + GNOME live ISO

Кастомный live-дистрибутив на базе Alpine Linux: GNOME, GRUB, набор
пакетов (Firefox, nano, git, GIMP), без `setup-alpine` при загрузке.

## Структура репозитория

```
scripts/                     — движок сборки ISO (mkimage), вендорено
                                из https://gitlab.alpinelinux.org/alpine/aports
                                (только scripts/, полное дерево aports
                                для сборки ISO не требуется — пакеты
                                качаются бинарно из репозиториев Alpine)
  mkimage.sh                  — точка входа, оригинал без изменений
  mkimg.base.sh                — базовая логика профилей, оригинал
  mkimg.standard.sh, ...       — остальные оригинальные профили (для справки)
  genapkovl-dhcp.sh            — оригинальный пример генератора оверлея (для справки)
  mkimg.mydistro.sh            — НАШ профиль (пакеты, grub, live)
  genapkovl-mydistro.sh        — НАШ генератор /etc-оверлея (автозапуск
                                  GNOME/NetworkManager, без setup-alpine)

.github/workflows/build-iso.yml — сборка ISO в GitHub Actions, результат
                                   в Actions → Artifacts

vendor/gcompat/               — исходники gcompat (глибц-совместимость).
                                 НЕ требуется для сборки — используется
                                 готовый apk-пакет gcompat из репозитория
                                 Alpine. Оставлено на случай, если
                                 понадобится собрать свою версию.

vendor/type2-runtime/         — исходники раннтайма AppImage под musl.
                                 НЕ требуется для базовой сборки — нужен
                                 только если захотите пересобрать свой
                                 AppImage-раннтайм вместо штатного
                                 fuse+gcompat.
```

## Как это работает

1. `mkimg.mydistro.sh` расширяет `profile_standard` (стандартный Alpine
   ISO-профиль) и добавляет пакеты GNOME + ваше ПО в переменную `apks`.
   Пакет ядра (`linux-lts`) подставляется отдельным механизмом движка
   через `kernel_flavors`, вручную его указывать не нужно.
2. `genapkovl-mydistro.sh` — при сборке движок сам вызывает этот скрипт,
   он генерирует архив `/etc`, который распаковывается поверх initramfs
   при загрузке live-системы: сеть по DHCP, автозапуск `dbus`,
   `networkmanager`, `elogind`, `polkit`, `gdm` в default runlevel.
   Результат — GNOME стартует сразу, без логина в консоль и без
   `setup-alpine`.
3. GRUB как загрузчик собирается автоматически (`mkimg.base.sh` уже
   содержит логику `build_grub_cfg`/`grub-mkimage` для гибридного
   isolinux+grub-efi ISO), отдельно настраивать не нужно.

## Локальная сборка (без GitHub Actions)

На Alpine-хосте или в `docker run -it --rm -v $PWD:/work alpine sh`:

```sh
apk add abuild alpine-conf syslinux xorriso squashfs-tools \
        grub grub-efi mtools dosfstools fakeroot
abuild-keygen -a -i
chmod +x scripts/*.sh
cd scripts
./mkimage.sh --profile mydistro --outdir /work/out --arch x86_64 \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community
```

Готовый `.iso` появится в `/work/out`.

## Сборка в GitHub Actions

Просто запушьте репозиторий и запустите workflow `Build MyDistro ISO`
(вкладка Actions → Run workflow), либо он запустится сам при пуше в
`main`, если менялись файлы в `scripts/`. Готовый ISO будет в разделе
Artifacts запуска.

## Что стоит проверить/доработать перед первым релизом

- Первая сборка почти наверняка потребует отладки — стоит прогнать
  локально прежде, чем полагаться на CI.
- Звук: добавлены `pipewire`, `pipewire-pulse`, `pipewire-alsa`,
  `wireplumber`, `alsa-utils`. Отдельный `rc_add` в OpenRC не нужен —
  pipewire запускается автоматически при входе в GNOME-сессию через
  XDG autostart (`.desktop`-файлы идут в составе самого пакета
  pipewire). Если после сборки звука всё же нет — проверить, что
  `gnome-control-center` показывает звуковые устройства
  (`pactl info` / `wpctl status` внутри сессии для диагностики).
- Также добавлен `gnome-control-center` — без него не было доступа
  к системным настройкам (звук, сеть, дисплей) из графического интерфейса.
- AppImage: `fuse` + `gcompat` уже добавлены в `apks` — для glibc-сборок
  этого обычно достаточно, см. обсуждение в предыдущих сообщениях.
- Если нужен пароль на root/пользователя в live-режиме — добавить его
  генерацию в `genapkovl-mydistro.sh` (сейчас пароль не выставляется,
  вход root без пароля через локальную консоль — стандартное поведение
  Alpine live).
