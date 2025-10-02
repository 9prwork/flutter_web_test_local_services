FROM ghcr.io/cirruslabs/flutter:stable-web AS build

WORKDIR /app

# คัดลอก pubspec ก่อนเพื่อ cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# คัดลอกโค้ดที่เหลือ
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