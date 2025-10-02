# -----------------------------
# Stage 1: Build Flutter Web
# -----------------------------
FROM ubuntu:22.04 AS build

# ตั้ง locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ติดตั้ง dependencies ของ Flutter
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง Flutter SDK
ENV FLUTTER_HOME=/flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# เปิด Flutter Web
RUN flutter config --enable-web
RUN flutter doctor -v

# ตั้ง working directory
WORKDIR /app

# copy pubspec ก่อนเพื่อ cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# copy code ที่เหลือ
COPY . .

# build Flutter Web
RUN flutter build web --release

# -----------------------------
# Stage 2: Serve ด้วย Nginx
# -----------------------------
FROM nginx:stable-alpine

# ลบ default config
RUN rm /etc/nginx/conf.d/default.conf

# copy build web
COPY --from=build /app/build/web /usr/share/nginx/html

# สร้าง nginx config สำหรับ Flutter Web
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 8080;

    location / {
        root   /usr/share/nginx/html;
        index  index.html;
        try_files \$uri /index.html;
    }
}
EOF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]