FROM debian:buster

LABEL tag="ackee-gitlab" \
      author="Ackee 🦄" \
      description="This Docker image serves as an environment for running Android builds on Gitlab CI in Ackee workspace"

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    curl \
    git \
    libgl1-mesa-glx \
    unzip \
    zip \
    python \
    wget \
    fontconfig

RUN curl -s "https://get.sdkman.io" | bash && \
    source "$HOME/.sdkman/bin/sdkman-init.sh" && \
    sdk install java 17.0.7-oracle && \
    sdk use java 17.0.7-oracle

ENV JAVA_HOME /root/.sdkman/candidates/java/current
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH "$PATH:$JAVA_HOME/bin"

# Download Android SDK command line tools into $ANDROID_HOME
RUN cd /opt && wget -q  https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip -O android-sdk-tools.zip && \
    unzip -q android-sdk-tools.zip && mkdir -p "$ANDROID_HOME/cmdline-tools/" && mv cmdline-tools latest && mv latest/ "$ANDROID_HOME"/cmdline-tools/ && \
    rm android-sdk-tools.zip

ENV PATH "$PATH:$ANDROID_HOME/cmdline-tools/latest:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Accept licenses before installing components
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

RUN sdkmanager "platform-tools"

# list all platforms, sort them in descending order, take the newest 8 versions and install them
RUN sdkmanager $(sdkmanager --list 2> /dev/null | grep platforms | awk -F' ' '{print $1}' | sort -nr -k2 -t- | head -8)
# list all build-tools, sort them in descending order and install them
RUN sdkmanager $(sdkmanager --list 2> /dev/null | grep build-tools | awk -F' ' '{print $1}' | sort -nr -k2 -t \; | uniq)

# install gcloud
RUN wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-334.0.0-linux-x86_64.tar.gz -O g.tar.gz && \
    tar xf g.tar.gz && \
    rm g.tar.gz && \
    mv google-cloud-sdk /opt/google-cloud-sdk && \
    /opt/google-cloud-sdk/install.sh -q && \
    /opt/google-cloud-sdk/bin/gcloud config set component_manager/disable_update_check true
# add gcloud SDK to path
ENV PATH="${PATH}:/opt/google-cloud-sdk/bin/"

## Danger-kotlin dependencies

# nvm environment variables
ENV NVM_DIR=/usr/local/nvm \
    NODE_VERSION=20.11.1

# install nvm
# https://github.com/creationix/nvm#install-script
RUN mkdir $NVM_DIR && \
    curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.7/install.sh | bash

RUN source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules \
    PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install make which is needed in danger-kotlin install phase
RUN apt-get update && apt-get install -y \
    make

# install danger-js which is needed for danger-kotlin to work
RUN npm install -g danger@11.3.1

# install kotlin compiler
RUN curl -o kotlin-compiler.zip -L https://github.com/JetBrains/kotlin/releases/download/v1.8.21/kotlin-compiler-1.8.21.zip && \
    unzip -d /usr/local/ kotlin-compiler.zip && \
    rm -rf kotlin-compiler.zip

# install danger-kotlin
RUN git clone https://github.com/danger/kotlin.git _danger-kotlin && \
    cd _danger-kotlin && git checkout 1.2.0 && \
    make install  && \
    cd ..  && \
    rm -rf _danger-kotlin

# setup environment variables
ENV PATH=$PATH:/usr/local/kotlinc/bin

# flutter
ENV FLUTTER_CHANNEL="stable"
ENV FLUTTER_VERSION="3.7.9"
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/linux/flutter_linux_$FLUTTER_VERSION-$FLUTTER_CHANNEL.tar.xz"
ENV FLUTTER_HOME="/opt/flutter"

RUN curl -o flutter.tar.xz $FLUTTER_URL \
  && mkdir -p $FLUTTER_HOME \
  && tar xf flutter.tar.xz -C /opt \
  && git config --global --add safe.directory /opt/flutter \
  && rm flutter.tar.xz

ENV PATH=$PATH:$FLUTTER_HOME/bin

RUN flutter config --no-analytics \
  && flutter precache \
  && yes "y" | flutter doctor --android-licenses \
  && flutter doctor \
  && flutter update-packages

# Dependency-Check Gradle plugin
#
# We use this Gradle plugin https://github.com/jeremylong/DependencyCheck for checking vulnerabilities in our dependencies, but it relies
# on env variable to determine encoding for dependency parsing, so we need to set this variable to make the task work as discussed and described more
# here https://github.com/jeremylong/DependencyCheck/issues/1742
ENV LC_ALL C.UTF-8

# git LFS support
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y git-lfs \
    && git lfs install

VOLUME /root/.gradle
