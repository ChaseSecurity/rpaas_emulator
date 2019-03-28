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
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-arm64
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/tools/bin

RUN apt-get -y install libswt-gtk-3-java
ENV ANDROID_SWT /usr/share/java/

# Install latest android tools and system images
RUN ( sleep 4 && while [ 1 ]; do sleep 1; echo y; done ) | \
    sdkmanager --install \
    "platform-tools" \
    "platforms;android-25" \
    #"platforms;android-28" \
    #"system-images;android-28;google_apis;armeabi-v7a" \
    "system-images;android-25;google_apis;armeabi-v7a"
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

# Add entrypoint
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
