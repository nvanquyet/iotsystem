# Stage 1: Build Flutter Web App
FROM cirrusci/flutter:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Xóa config default của nginx
RUN rm -rf /usr/share/nginx/html/*

# Copy file build web từ stage 1 vào thư mục web server của nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
