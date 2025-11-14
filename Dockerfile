# Stage 1: Build app for linux/amd64-compatible runtime (pull from Amazon ECR Public to avoid Docker Hub rate limits)
FROM public.ecr.aws/docker/library/node:20-bullseye-slim AS build
WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --no-audit --no-fund

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx (ECR Public mirror)
FROM public.ecr.aws/nginx/nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
