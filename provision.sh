#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.
set -u  # Treat unset variables as an error when substituting.
set -v  # Print shell input lines as they are read.
set -x  # Print commands and their arguments as they are executed.

# устанавливаем jq:
sudo dnf --assumeyes install jq

# устанавливаем поддержку ZFS
# (DKMS, так как kmod не поддерживается в CentOS Stream 9):
DIST=$(rpm --eval '%{dist}')
sudo dnf --assumeyes install \
  "https://zfsonlinux.org/epel/zfs-release-2-3${DIST}.noarch.rpm"
sudo dnf --assumeyes install epel-release
sudo dnf --assumeyes install kernel-devel
sudo dnf --assumeyes install zfs
sudo modprobe zfs

# разбиение дисков до создания zfs pool:
lsblk | tee "/vagrant/lsblk-before.txt"

# получаем список дисков (кроме системного):
DISKS=$(lsblk --json --tree --bytes -o NAME,TYPE,SIZE,MOUNTPOINT \
  | jq -r '.blockdevices[] | select(.type=="disk")' \
  | jq -r 'select([recurse(.children[]?)] | all(.mountpoint!="/"))' \
  | jq -r '.name')

# создаём ZFS draid3 из 29 дисков:
# - 22 диска под данные
# - 6 дисков под parity
# - 1 hot spare
sudo zpool create tank draid3:11d:29c:1s ${DISKS}

# предварительно скачиваем файл для тестирования алгоритмов сжатия:
curl --output "/tmp/data.log" \
  "https://gutenberg.org/cache/epub/2600/pg2600.converter.log"

# создаём файловые системы со всеми поддерживаемыми алгоритмами сжатия,
# копируем туда data.log:
COMPRESSIONS="lz4 lzjb zle"
for i in {1..9}; do COMPRESSIONS="${COMPRESSIONS} gzip-${i}"; done
for i in {1..19}; do COMPRESSIONS="${COMPRESSIONS} zstd-${i}"; done
for i in {1..9}; do COMPRESSIONS="${COMPRESSIONS} zstd-fast-${i}"; done
for i in {1..9}; do COMPRESSIONS="${COMPRESSIONS} zstd-fast-${i}0"; done
COMPRESSIONS="${COMPRESSIONS} zstd-fast-100 zstd-fast-500 zstd-fast-1000"
for alg in ${COMPRESSIONS}; do
  sudo zfs create -o compression="${alg}" "tank/${alg}"
  sudo cp "/tmp/data.log" "/tank/${alg}/"
done

# сохраняем информацию о степени сжатия:
zfs get compressratio | (sed -u '1q'; sort -k3) \
  | tee "/vagrant/compressratio.txt"

# скачиваем пула в домашний каталог и распаковываем его:
curl --output - \
  "https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download" \
  | tar --extract --gzip

# импортируем пул otus из файлов:
sudo zpool import -d zpoolexport otus

# сохраним опции пула otus:
zfs get all otus | tee "/vagrant/otus-props.txt"
zfs get type,available,readonly,recordsize,compression,checksum otus \
  | tee "/vagrant/otus-props-filtered.txt"

# скачаем snapshot пула otus:
curl --output "otus_task2.file" \
  "https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download"

# восстанавливаем файловую систему из snapshot:
sudo zfs receive otus/test@today < otus_task2.file

# ищем файл secret_message и отображаем его содержимое:
SECRET_FILE=$(find "/otus/test" -name "secret_message")
echo "FILE: ${SECRET_FILE}" | tee "/vagrant/secret.txt"
echo "CONTENT:" | tee --append "/vagrant/secret.txt"
cat "${SECRET_FILE}" | tee --append "/vagrant/secret.txt"

# проверим работу дедупликации:
dd if=/dev/zero of="${HOME}/dedup_pool" bs=1M count=128
sudo zpool create dedup "${HOME}/dedup_pool"
sudo zfs set dedup=verify dedup
for i in {1..20}; do sudo cp "/tmp/data.log" "/dedup/${i}.log"; done
# мы записали 20 файлов по 40M на диск в 128M (на самом деле меньше)
# дедупликация работает
ls -lah /dedup/ | tee "/vagrant/ls-dedup.txt"

# собираем иные логи о выполнении задания:
lsblk | tee "/vagrant/lsblk-after.txt"
zpool list | tee "/vagrant/zpool-list.txt"
zpool status -D | tee "/vagrant/zpool-status.txt"
zfs list | tee "/vagrant/zfs-list.txt"
