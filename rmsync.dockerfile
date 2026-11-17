FROM dhi.io/alpine-base:3.24-dev

# Enable community repository for pandoc
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.24/community" >> /etc/apk/repositories 

# Install dependencies
RUN apk add --no-cache \
        bash=5.3.9-r1 \
        jq=1.8.2_git20261021-r2 \
        curl=8.23.0-r0 \
        pandoc-cli=3.10-r0 \
        zip=3.0-r13 \
        unzip=6.0-r16

# Creates work directory (if it does not exist) 
RUN mkdir -p /work && chown nonroot:nonroot /work
WORKDIR /work

# Install Redmine Sync script
COPY scripts/redmine_sync.sh /work/entrypoint.sh
RUN chown 65532:65532 /work/entrypoint.sh
RUN chmod +x /work/entrypoint.sh

# Switch to nonroot user
USER 65532:65532

ENTRYPOINT ["./entrypoint.sh"]
