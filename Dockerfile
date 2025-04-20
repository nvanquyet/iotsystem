FROM cirrusci/flutter:stable

# Cài đặt Android SDK tools
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
RUN yes | sdkmanager --licenses

# Thêm biến môi trường cho PATH
ENV PATH="$PATH:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin"

WORKDIR /app
COPY . .

RUN flutter pub get

# Build APK (release)
RUN flutter build apk --release
