FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static frontend files
COPY public/ /usr/share/nginx/html/

# Create a non-root user and adjust permissions
RUN addgroup -S frontgroup && adduser -S frontuser -G frontgroup \
    && chown -R frontuser:frontgroup /usr/share/nginx/html \
    && chown -R frontuser:frontgroup /var/cache/nginx \
    && chown -R frontuser:frontgroup /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown -R frontuser:frontgroup /var/run/nginx.pid

# Expose port 80
EXPOSE 80

# Switch to non-root user
USER frontuser

# Health check: HTTP request on root
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
