FROM debian:stretch

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    curl \
    git \
    openjdk-8-jdk-headless \
    unzip \
    wget

ENV ANDROID_HOME /opt/android-sdk-linux
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin

# Download Android SDK tools into $ANDROID_HOME
RUN cd /opt && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip && \
    unzip -q android-sdk-tools.zip && mkdir -p "$ANDROID_HOME" && mv tools/ "$ANDROID_HOME"/tools/ && \
    rm android-sdk-tools.zip

ENV PATH "$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# Accept licenses before installing components
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

RUN sdkmanager "platform-tools"

# list all platforms, sort them in descending order, take the newest 8 versions and install them
RUN sdkmanager $(sdkmanager --list 2> /dev/null | grep platforms | awk -F' ' '{print $1}' | sort -nr -k2 -t- | head -8)
# list all build-tools, sort them in descending order and install them
RUN sdkmanager $(sdkmanager --list 2> /dev/null | grep build-tools | awk -F' ' '{print $1}' | sort -nr -k2 -t \; | uniq)

# install Appium
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g appium --unsafe-perm=true
