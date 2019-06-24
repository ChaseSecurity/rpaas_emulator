# Android development environment for ubuntu.
# version 0.0.5

FROM ubuntu:18.04

MAINTAINER xianghang <xianghangmi@gmail.com>

# Specially for SSH access and port redirection
ENV ROOTPASSWORD rpaas

# Expose ADB, ADB control and VNC ports
EXPOSE 22
EXPOSE 5037
EXPOSE 5554
EXPOSE 5555
EXPOSE 5900
EXPOSE 80
EXPOSE 443

ENV DEBIAN_FRONTEND noninteractive
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

# Update packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common bzip2 ssh net-tools openssh-server socat curl && \
    apt-get install -y --no-install-recommends openjdk-8-jdk &&  \
    rm -rf /var/lib/apt/lists/*
# install kvm
RUN apt-get -y update && \
    apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
# Install android sdk
# download and install Android SDK
# https://developer.android.com/studio/#downloads
ARG ANDROID_SDK_VERSION=4333796
ENV ANDROID_HOME /usr/local/android-sdk
RUN mkdir -p ${ANDROID_HOME} && cd ${ANDROID_HOME} && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip
#RUN wget -qO- http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | \
#    tar xvz -C /usr/local/ && \
#    mv /usr/local/android-sdk-linux /usr/local/android-sdk && \
#    chown -R root:root /usr/local/android-sdk/
# ENV ANDROID_HOME /usr/local/android-sdk

# Add android tools and platform tools to PATH
# set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/tools/bin

#RUN apt-get -y install libswt-gtk-3-java
#ENV ANDROID_SWT /usr/share/java/

# Install latest android tools and system images
RUN ( sleep 4 && while [ 1 ]; do sleep 1; echo y; done ) | \
    sdkmanager --install \
    "platform-tools" \
    "platforms;android-25" \
    #"platforms;android-28" \
    #"system-images;android-28;google_apis;armeabi-v7a" \
    "system-images;android-25;google_apis;armeabi-v7a" \
    "system-images;android-25;google_apis;x86" \
    "system-images;android-25;google_apis;x86_64" \
    "system-images;android-28;google_apis;x86" \
    "system-images;android-28;google_apis;x86_64"
RUN ( sleep 4 && while [ 1 ]; do sleep 1; echo y; done ) | \
    sdkmanager --install \
    "emulator"
ENV PATH $PATH:$ANDROID_HOME/tools/platform-tools


#RUN echo "y" | android update adb
# Create fake keymap file
RUN mkdir /usr/local/android-sdk/tools/keymaps && \
    touch /usr/local/android-sdk/tools/keymaps/en-us

# Run sshd
RUN mkdir /var/run/sshd && \
    echo "root:$ROOTPASSWORD" | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile

ENV NOTVISIBLE "in users profile"

# Run vnc
ENV DISPLAY :1
ADD vncpass.sh /tmp/
ADD watchdog.sh /usr/local/bin/
ADD supervisord_vncserver.conf /etc/supervisor/conf.d/
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xfce4 xfce4-goodies xfonts-base dbus-x11 tightvncserver expect && \
    chmod +x /tmp/vncpass.sh; sync && \
    /tmp/vncpass.sh && \
    rm /tmp/vncpass.sh && \
    apt-get remove -y expect && apt-get autoremove -y && \
    FILE_SSH_ENV="/root/.ssh/environment" && \
    mkdir -p /root/.ssh && \
    echo "DISPLAY=:1" >> $FILE_SSH_ENV

ADD supervisord.conf /etc/supervisor/conf.d/
ADD sshd-banner /etc/ssh/
ADD authorized_keys /tmp/
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openssh-server supervisor locales && \
    mkdir -p /var/run/sshd /var/log/supervisord && \
    locale-gen en en_US en_US.UTF-8 && \
    apt-get remove -y locales && apt-get autoremove -y && \
    FILE_SSHD_CONFIG="/etc/ssh/sshd_config" && \
    echo "\nBanner /etc/ssh/sshd-banner" >> $FILE_SSHD_CONFIG && \
    echo "\nPermitUserEnvironment=yes" >> $FILE_SSHD_CONFIG && \
    ssh-keygen -q -N "" -f /root/.ssh/id_rsa && \
    FILE_SSH_ENV="/root/.ssh/environment" && \
    touch $FILE_SSH_ENV && chmod 600 $FILE_SSH_ENV && \
    printenv | grep "JAVA_HOME\|GRADLE_HOME\|KOTLIN_HOME\|ANDROID_HOME\|LD_LIBRARY_PATH\|PATH" >> $FILE_SSH_ENV && \
    FILE_AUTH_KEYS="/root/.ssh/authorized_keys" && \
    touch $FILE_AUTH_KEYS && chmod 600 $FILE_AUTH_KEYS && \
    for file in /tmp/*.pub; \
    do if [ -f "$file" ]; then echo "\n" >> $FILE_AUTH_KEYS && cat $file >> $FILE_AUTH_KEYS && echo "\n" >> $FILE_AUTH_KEYS; fi; \
    done && \
    (rm /tmp/*.pub 2> /dev/null || true)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git wget unzip && \
    apt-get install -y --no-install-recommends qt5-default && \
    apt-get install -y python3-dev python3-pip libffi-dev libssl-dev && \
    pip3 install mitmproxy  # or pip3 install --user mitmproxy

EXPOSE 5901
ENV USER root
ENV PATH $PATH:$ANDROID_HOME/platform-tools
# Add entrypoint
ADD entrypoint.sh /entrypoint.sh
ADD start_avd.sh /start_avd.sh
RUN chmod +x /entrypoint.sh
#CMD ["/usr/bin/supervisord"]
ENTRYPOINT ["/entrypoint.sh"]
