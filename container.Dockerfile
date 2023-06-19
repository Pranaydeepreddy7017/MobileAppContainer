#stage 1: Build stage
FROM debian:bullseye-slim as builder
ARG ANDROID_SDK_VERSION=7583922_latest
ARG ANDROID_NDK_VERSION=21.4.7075529

ENV ANDROID_NDK_HOME=/opt/android-ndk-r25c
ENV ANDROID_HOME=/opt/android-sdk
ENV GRADLE_VERSION 8.0.2


WORKDIR "/opt"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    openjdk-11-jdk-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
# Download and install Android SDK
    &&curl -sSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}.zip" -o sdk.zip \
    && unzip -q sdk.zip -d "${ANDROID_HOME}" \
    && rm sdk.zip \
    && mkdir ${ANDROID_HOME}/tools && mv ${ANDROID_HOME}/cmdline-tools/* ${ANDROID_HOME}/tools/ && mv ${ANDROID_HOME}/tools ${ANDROID_HOME}/cmdline-tools/ \
    && yes | ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --licenses \
    && ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager "platform-tools" "platforms;android-31" \
    && ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --update \
# Download and install Android NDK
    && curl -sSL https://dl.google.com/android/repository/android-ndk-r25c-linux.zip -o ndk.zip \
# Install Gradle
    && curl -sSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o gradle.zip \
    && unzip -q gradle.zip -d /opt/gradle 

# Stage 2: Final stage
FROM debian:bullseye-slim

# Install Node.js
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@9 \
    # Install React Native CLI
    && npm install -g --unsafe-perm=true --allow-root react-native-cli

# Copy installed dependencies from the build stage
COPY --from=builder /opt/android-sdk /opt/android-sdk
COPY --from=builder /opt/android-ndk-r25c /opt/android-ndk-r25c
COPY --from=builder /opt/gradle /opt/gradle


ENV ANDROID_NDK_HOME=/opt/android-ndk-r25c
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/tools/emulator:$ANDROID_HOME/cmdline-tools/tools:$ANDROID_HOME/cmdline-tools/tools/bin:$ANDROID_HOME/cmdline-tools/tools/platform-tools:/opt/gradle/gradle-8.0.2/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-essential \
    openjdk-11-jdk-headless \
    git \
    file \
    && gem install fastlane -v 2.212.1 \
    && gem install bundler

# Set working directory
WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
