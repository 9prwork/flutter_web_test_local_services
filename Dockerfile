# Stage 1: ติดตั้ง Flutter SDK และ dependencies
FROM ubuntu:20.04 AS build

# ติดตั้ง dependencies ที่จำเป็น
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    xz-utils \
    libglu1-mesa \
    fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# เปิดใช้งาน Flutter Web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

WORKDIR /app

# คัดลอกไฟล์ที่จำเป็น
COPY pubspec.* ./
RUN flutter pub get

# คัดลอกโค้ดทั้งหมด
COPY . .

# สร้าง Flutter Web
RUN flutter build web --release

# Stage 2: ใช้ Nginx serve static files
FROM nginx:stable-alpine

# ลบ default config
RUN rm /etc/nginx/conf.d/default.conf

# คัดลอก build web ไปยัง nginx html
COPY --from=build /app/build/web /usr/share/nginx/html

# ใส่ config nginx ให้รองรับ Flutter web (history fallback)
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