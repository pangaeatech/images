FROM dhi.io/debian-base:trixie-debian13-dev

# renovate: datasource=github-tags depName=github/copilot.vim versioning=semver extractVersion=^v(?<version>.*)$
ENV COPILOT_VIM_VERSION=1.59.0

# renovate: datasource=github-releases depName=anomalyco/opencode versioning=semver extractVersion=^v(?<version>.*)$
ENV OPENCODE_VERSION=2.2.7

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        jq="1.8.*" \
        curl="8.14.*" \
        pandoc="3.1.*" \
        zip="3.*" \
        unzip="6.*" \
        doxygen="1.9.*" \
        nodejs-24="24.22.*" \
        npm-12="12.2.*" \
        git="1:2.47.*" \
        python3-pip="26.*" \
        python3-venv="3.13.*" \
        python3-dev="3.13.*" \
        python3-poetry="2.1.*" \
        build-essential="12.*" \
        neovim="0.10.*"

# Install .NET SDK
RUN touch /etc/shells
RUN curl -fsSL -o packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
        dotnet-sdk-10.0=10.0.403-1 \
        powershell=7.6.9-1.deb

# Install copilot.vim plugin for neovim
RUN curl -L -o /tmp/copilot.vim.tar.gz https://github.com/github/copilot.vim/archive/refs/tags/v${COPILOT_VIM_VERSION}.tar.gz && \
    tar -xzf /tmp/copilot.vim.tar.gz -C /tmp && \
    mkdir -p /root/.config/nvim/pack/github/start && \
    mv /tmp/copilot.vim-${COPILOT_VIM_VERSION} /root/.config/nvim/pack/github/start/copilot.vim && \
    rm /tmp/copilot.vim.tar.gz

# Install opencode
RUN curl -L -o /tmp/opencode.deb https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-desktop-linux-amd64.deb && \
    apt-get install -y --no-install-recommends /tmp/opencode.deb && \
    rm /tmp/opencode.deb

# Delete apt cache to reduce image size
RUN rm -Rf /var/lib/apt/lists/*

# Creates work directory (if it does not exist) 
RUN mkdir -p /work && chown nonroot:nonroot /work
WORKDIR /work

# Switch to nonroot user
USER 65532:65532

CMD ["/bin/bash"]
