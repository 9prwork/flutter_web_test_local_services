# ใช้ Nginx serve Flutter Web
FROM nginx:alpine

# คัดลอก build/web เข้า folder html ของ nginx
COPY build/web /usr/share/nginx/html

# expose port 80
EXPOSE 80

# run nginx foreground
CMD ["nginx", "-g", "daemon off;"]