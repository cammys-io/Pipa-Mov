# Etapa 1: Compilar Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Descarga de dependencias
COPY pubspec.yaml ./
RUN flutter pub get

# Copiar el código fuente y compilar para web
COPY . .
RUN flutter build web --release

# Etapa 2: Servidor Nginx ultra ligero para producción
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
