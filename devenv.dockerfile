FROM dhi.io/debian-base:trixie-debian13-dev@sha256:f90fd43cdf3dd94840b4dc3a2a39fd2a08578e40e7895535e2e20a1275ba6013

# renovate: datasource=github-tags depName=github/copilot.vim versioning=semver extractVersion=^v(?<version>.*)$
ENV COPILOT_VIM_VERSION=1.59.0

# renovate: datasource=npm depName=opencode-ai
ENV OPENCODE_VERSION=1.18.31

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        jq=1.8.2-1+deb13u0+dhi1 \
        curl=8.14.1-2+deb13u7+dhi1 \
        pandoc=3.1.11.1+ds-2 \
        zip=3.0-15+deb13u1+dhi1 \
        unzip=6.0-29+deb13u1+dhi1 \
        gh=2.46.0-3 \
        doxygen=1.9.8+ds-2.1 \
        nodejs-24=24.22.3-0 \
        npm-12=12.2.2-1 \
        git=1:2.47.3-0+deb13u1+dhi3 \
        python3-pip=26.3-0 \
        python3-venv=3.13.5-1+deb13u0+dhi0 \
        python3-dev=3.13.5-1+deb13u0+dhi0 \
        python3-poetry=2.1.2+dfsg-1+deb13u1 \
        neovim=0.10.4-8 \
        rcm=1.3.4-1 \
        hub=2.14.2~ds1-1+b23

# Install .NET SDK
RUN touch /etc/shells
RUN curl -fsSL -o packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y --no-install-recommends dotnet-sdk-10.0=10.0.404-1 
RUN apt-get update && apt-get install -y --no-install-recommends powershell=7.6.9-1.deb

# Install copilot.vim plugin for neovim
RUN curl -L -o /tmp/copilot.vim.tar.gz https://github.com/github/copilot.vim/archive/refs/tags/v${COPILOT_VIM_VERSION}.tar.gz && \
    tar -xzf /tmp/copilot.vim.tar.gz -C /tmp && \
    mkdir -p /root/.config/nvim/pack/github/start && \
    mv /tmp/copilot.vim-${COPILOT_VIM_VERSION} /root/.config/nvim/pack/github/start/copilot.vim && \
    rm /tmp/copilot.vim.tar.gz

# Install opencode
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# Delete apt cache to reduce image size
RUN rm -Rf /var/lib/apt/lists/*

# Setup home
COPY scripts/devenv-bash.sh /etc/bash_bootstrap
RUN echo '. /etc/bash_bootstrap' >> /etc/bash.bashrc

# Creates work directory and makes globally writable (for other UIDs)
RUN mkdir -p /home/nonroot/work \
    && chmod -R 666 /home/nonroot \
    && chmod 777 /home/nonroot \
    && chmod 777 /home/nonroot/work

WORKDIR /home/nonroot/work

# Switch to nonroot user
USER 65532:65532

CMD ["/bin/bash"]
