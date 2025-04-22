FROM cirrusci/flutter:stable

WORKDIR /app

COPY pubspec.* ./

RUN flutter pub get

COPY . .

RUN flutter build apk --release


# RUN flutter build ios --release --no-codesign
# EXPOSE 8080
# Tùy chọn: Command mặc định khi chạy container
# CMD ["flutter", "run", "--release"]