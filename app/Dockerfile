# 1. The Base Image (The Waiter)
# We use Nginx (a lightweight web server) to serve our HTML.
FROM nginx:alpine

# 2. The Content (The Food)
# We copy our HTML file from our laptop into the container's specialized folder.
COPY index.html /usr/share/nginx/html/index.html

# 3. The Door (The Port)
# We open port 80 so the world can see it.
EXPOSE 80
