#!/bin/bash

## Run sshd
#/usr/sbin/sshd
#
#/usr/bin/supervisord
#/usr/sbin/sshd
#/usr/bin/vncserver &
#/usr/local/bin/watchdog.sh &
#sleep 10

# Detect ip and forward ADB ports outside to outside interface
ip=$(ifconfig  | grep 'inet '| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $2}')
echo $ip
socat tcp-listen:5037,bind=$ip,fork tcp:127.0.0.1:5037 &
socat tcp-listen:5554,bind=$ip,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind=$ip,fork tcp:127.0.0.1:5555 &
socat tcp-listen:80,bind=$ip,fork tcp:127.0.0.1:80 &
socat tcp-listen:443,bind=$ip,fork tcp:127.0.0.1:443 &

emu_list=(
    "system-images;android-25;google_apis;armeabi-v7a"
    "system-images;android-25;google_apis;x86"
    "system-images;android-25;google_apis;x86_64"
)
tag_list=('25_arm' '25_x86' '25_x86_64')
avd_index=0
for emu in ${emu_list[@]};
do
    echo "emu is $emu"
    tag=${tag_list[$avd_index]}
    echo "no" | /usr/local/android-sdk/tools/bin/avdmanager create avd -f -n test_${tag} -k $emu -c 256M
    avd_index=$(($avd_index + 1))
done 
/usr/bin/supervisord
#echo "no" | /usr/local/android-sdk/emulator/emulator -avd test -noaudio -gpu off -verbose $FORCE_32 -no-boot-anim -writable-system #-no-window -qemu -vnc :0
