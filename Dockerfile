# Stage 1: Build app for linux/amd64-compatible runtime
FROM node:20-bullseye-slim AS build
WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --no-audit --no-fund

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html/

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Switch to the non-root user
USER appuser

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
