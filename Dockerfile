FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    pandoc \
    jq \
    ca-certificates \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Tectonic (TeX engine)
# Debian is better for Tectonic binary compatibility (glibc)
RUN curl --proto '=https' --tlsv1.2 -fsSL https://drop.tectonic.new | sh \
    && mv tectonic /usr/local/bin/

WORKDIR /app

# Copy scripts
COPY deploy.sh /app/deploy.sh
COPY deploy-loop.sh /app/deploy-loop.sh
COPY create_web.sh /app/create_web.sh
COPY create_book.sh /app/create_book.sh

RUN chmod +x /app/*.sh

# Create repo directory structure
RUN mkdir -p /app/repo /app/output

ENTRYPOINT ["/app/deploy-loop.sh"]
