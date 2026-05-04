FROM nginx:1.25-alpine

# Pre-create nginx cache directories and fix permissions during build
RUN mkdir -p /var/cache/nginx/client_temp \
    && mkdir -p /var/cache/nginx/proxy_temp \
    && mkdir -p /var/cache/nginx/uwsgi_temp \
    && chmod -R 777 /var/cache/nginx \
    && chmod 777 /var/run

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static frontend files
COPY public/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Health check: HTTP request on root
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
