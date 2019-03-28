# Android development environment for ubuntu.
# version 0.0.5

FROM ubuntu

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
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    apt-get -y install oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/*
# install kvm
RUN apt-get -y update && \
    apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
# Install android sdk
RUN wget -qO- http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | \
    tar xvz -C /usr/local/ && \
    mv /usr/local/android-sdk-linux /usr/local/android-sdk && \
    chown -R root:root /usr/local/android-sdk/

# Add android tools and platform tools to PATH
ENV ANDROID_HOME /usr/local/android-sdk
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

# Install latest android tools and system images
RUN ( sleep 4 && while [ 1 ]; do sleep 1; echo y; done ) | android update sdk --no-ui --force -a --filter \
    2,4,android-25,android-28,sys-img-armeabi-v7a-google_apis-25,sys-img-armeabi-v7a-google_apis-28,sys-img-x86-google_apis-25,sys-img-x86-google_apis-28


# echo "y" | android update adb
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
