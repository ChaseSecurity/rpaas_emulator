#!/bin/bash

if [[ $EMULATOR == "" ]]; then
    EMULATOR="system-images;android-25;google_apis;armeabi-v7a"
    echo "Using default emulator $EMULATOR"
fi

if [[ $ARCH == "" ]]; then
    ARCH="google_apis/armeabi-v7a"
    echo "Using default arch $ARCH"
fi
if [[ $FORCE_32 != "" ]];then
    FORCE_32=" -force-32bit "
    echo "Using force-32"
fi
echo EMULATOR  = "Requested API: ${EMULATOR} (${ARCH}) emulator."
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi

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

# Set up and run emulator
if [[ $ARCH == *"x86"* ]]
then 
    EMU="x86"
else
    EMU="arm"
fi

echo "no" | /usr/local/android-sdk/tools/bin/avdmanager create avd -f -n rpaas -k ${EMULATOR} --abi ${ARCH} -c 256M
/usr/bin/supervisord
#echo "no" | /usr/local/android-sdk/emulator/emulator -avd test -noaudio -gpu off -verbose $FORCE_32 -no-boot-anim -writable-system #-no-window -qemu -vnc :0
