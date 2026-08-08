FROM nginx:alpine

# Install curl for container health monitoring
RUN apk add --no-cache curl

# Copy static web asset
COPY index.html /usr/share/nginx/html/index.html

# Expose HTTP port
EXPOSE 80

# Production Healthcheck for Kubernetes pod lifecycle management
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start Nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
