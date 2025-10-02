# Stage 1: Build Flutter Web
FROM cirrusci/flutter:3.35.5 AS build

WORKDIR /app

# copy pubspec ก่อนเพื่อ cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# copy source code ที่เหลือ
COPY . .

# build flutter web
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:stable-alpine

# remove default config
RUN rm /etc/nginx/conf.d/default.conf

# copy build web
COPY --from=build /app/build/web /usr/share/nginx/html

# nginx config for Flutter web (history fallback)
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