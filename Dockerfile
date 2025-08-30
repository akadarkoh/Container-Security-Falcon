# Stage 1: Build app
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html/   # (React = /build, Vite = /dist)
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

