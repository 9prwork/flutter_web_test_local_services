# Stage 1: Build Flutter Web
FROM cirrusci/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files and get dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy all source code
COPY . .

# Build the Flutter web app
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# Copy built web app from builder
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]