FROM dhi.io/node:26-alpine-dev@sha256:4ae4a2b1bb72ce18f187d03a5112b738b5b02d85f9d33d53883a4ade7b511ba4

# Enable community repository for pandoc
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.24/community" >> /etc/apk/repositories 

# Install dependencies
RUN apk add --no-cache \
        bash=5.3.9-r1 \
        jq=1.8.2_git20261021-r2 \
        curl=8.23.0-r0 \
        pandoc-cli=3.10-r0 \
        zip=3.0-r13 \
        unzip=6.0-r16 \
        github-cli=2.97.0-r2

# Create non-root user
RUN addgroup -g 65532 -S nonroot && \
    adduser -u 65532 -D -S -G nonroot nonroot

# Creates work directory (if it does not exist) 
RUN mkdir -p /work && chown nonroot:nonroot /work
WORKDIR /work

# Install Redmine Sync script
COPY scripts/*.sh /work/
COPY scripts/lib/ /work/lib/
RUN chown -R 65532:65532 /work && chmod +x /work/*.sh

# Switch to nonroot user
USER 65532:65532

ENTRYPOINT ["/work/redmine_sync.sh"]
