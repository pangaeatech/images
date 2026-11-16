FROM dhi.io/debian-base:trixie-debian13-dev

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
        build-essential="12.*" 

# Install .NET SDK
RUN touch /etc/shells
RUN curl -fsSL -o packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
        dotnet-sdk-10.0=10.0.403-1 \
        powershell=7.6.9-1.deb

# Delete apt cache to reduce image size
RUN rm -Rf /var/lib/apt/lists/*

# Creates work directory (if it does not exist) 
RUN mkdir -p /work && chown nonroot:nonroot /work
WORKDIR /work

# Switch to nonroot user
USER 65532:65532

CMD ["/bin/bash"]
