# ใช้ base image ของ Flutter ที่รองรับ web
FROM ghcr.io/cirruslabs/flutter:stable-web AS build

# ตั้งค่า working directory
WORKDIR /app

# คัดลอกไฟล์ pubspec และ pubspec.lock ก่อน เพื่อให้สามารถใช้ cache ในการติดตั้ง dependencies
COPY pubspec.* ./

# ติดตั้ง dependencies
RUN flutter pub get

# คัดลอก source code ทั้งหมด
COPY . .

# สร้างแอปในโหมด release สำหรับ web
RUN flutter build web --release

# ใช้ Nginx เพื่อ serve แอป
FROM nginx:stable-alpine

# ลบ default config ของ Nginx
RUN rm /etc/nginx/conf.d/default.conf

# คัดลอกไฟล์ที่ build แล้วไปยัง directory ที่ Nginx ใช้
COPY --from=build /app/build/web /usr/share/nginx/html

# ตั้งค่า Nginx ให้รองรับ Flutter Web
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 8080;
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri /index.html;
    }
}
EOF

# เปิด port 8080
EXPOSE 8080

# เริ่มต้น Nginx
CMD ["nginx", "-g", "daemon off;"]