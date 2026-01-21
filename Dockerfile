FROM alpine:latest

# Install dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    pandoc \
    jq \
    sed \
    openssh-client

# Install Tectonic (TeX engine)
# Using a widely compatible static binary or standard install if available
# Alpine edge/community sometimes has it, but binary download is reliable
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
