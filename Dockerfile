# Step 1: Build Flutter Web
FROM debian:stable-slim AS build

# ติดตั้ง dependencies
RUN apt-get update && apt-get install -y \
    curl unzip xz-utils git libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# ติดตั้ง Flutter SDK
ENV FLUTTER_VERSION=3.24.3
RUN git clone https://github.com/flutter/flutter.git /flutter -b $FLUTTER_VERSION
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# เปิดใช้งาน Flutter web
RUN flutter config --enable-web

# copy source code
WORKDIR /app
COPY flutter_app/ .

# ติดตั้ง dependencies และ build
RUN flutter pub get
RUN flutter build web --release

# Step 2: ใช้ Nginx serve static files
FROM nginx:stable-alpine

# ลบ default config
RUN rm /etc/nginx/conf.d/default.conf

# copy build ออกมาไว้ใน nginx html
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