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
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-recommended \
    && rm -rf /var/lib/apt/lists/*

# (Removed Tectonic installer due to DNS unreliability. Using texlive-xetex instead.)

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
