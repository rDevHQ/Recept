FROM debian:bookworm-slim

# Install dependencies
# Added nginx
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    pandoc \
    jq \
    ca-certificates \
    openssh-client \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-recommended \
    nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy scripts
COPY deploy.sh /app/deploy.sh
COPY deploy-loop.sh /app/deploy-loop.sh
COPY create_web.sh /app/create_web.sh
COPY create_book.sh /app/create_book.sh
COPY start.sh /app/start.sh

RUN chmod +x /app/*.sh

# Configure Nginx to run in foreground or background?
# We will use start.sh to control it.
# Adjust Nginx default site to point to where we deploy (/data/public)
# We can do this with sed in the Dockerfile to "bake it in"
RUN sed -i 's|/var/www/html|/data/public|g' /etc/nginx/sites-available/default
# Also ensure it listens on 80 (default)

ENTRYPOINT ["/app/start.sh"]
