FROM nginx:alpine

# Configure Nginx to return 500 for everything
RUN echo 'server { \
  listen 8069; \
  location / { return 500 "Simulated Failure for Rollback"; } \
  }' > /etc/nginx/conf.d/default.conf

EXPOSE 8069 