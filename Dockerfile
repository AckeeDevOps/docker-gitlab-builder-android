FROM debian:stretch

RUN apt-get update && apt-get install -y \
    git \
    openjdk-8-jdk-headless \
    unzip \
    wget

ENV ANDROID_HOME /opt/android-sdk-linux

RUN cd /opt && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip && \
    unzip -q android-sdk-tools.zip && mkdir -p "$ANDROID_HOME" && mv tools/ "$ANDROID_HOME"/tools/ && \
    rm android-sdk-tools.zip

RUN cd "$ANDROID_HOME" && wget -q https://dl.google.com/android/repository/android-ndk-r21-linux-x86_64.zip -O ndk-bundle.zip && \
    unzip -q ndk-bundle.zip && mv android-ndk-r21 ndk-bundle && rm -r ndk-bundle.zip

ENV PATH "$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# Accept licenses before installing components
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

RUN sdkmanager "platform-tools"
