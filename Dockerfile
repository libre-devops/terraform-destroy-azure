FROM ubuntu:24.04

LABEL org.opencontainers.image.title=runner
LABEL org.opencontainers.image.source=https://github.com/libre-devops/terraform-azure-composite-gh-action

ARG NORMAL_USER=builder
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH="linux-x64"

ENV NORMAL_USER=${NORMAL_USER}
ENV DEBIAN_FRONTEND=noninteractive
ENV TARGETARCH=${TARGETARCH}
ENV HOME=/home/${NORMAL_USER}
ENV PYENV_ROOT=/home/${NORMAL_USER}/.pyenv

ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${NORMAL_USER}/.pyenv:/home/${NORMAL_USER}/.pyenv/bin:/home/${NORMAL_USER}/.local:/home/${NORMAL_USER}/.tenv:/home/${NORMAL_USER}/.tenv/bin:/home/${NORMAL_USER}/.pkenv:/home/${NORMAL_USER}/.pkenv/bin:/home/${NORMAL_USER}/.goenv:/home/${NORMAL_USER}/.goenv/bin:/home/${NORMAL_USER}/.jenv:/home/${NORMAL_USER}/.jenv/bin:/home/${NORMAL_USER}/.nvm:/home/${NORMAL_USER}/.rbenv:/home/${NORMAL_USER}/.rbenv/bin:/home/${NORMAL_USER}/.sdkman:/home/${NORMAL_USER}/.sdkman/bin:/home/${NORMAL_USER}/.dotnet:/home/${NORMAL_USER}/.cargo:/home/${NORMAL_USER}/.cargo/bin:/home/${NORMAL_USER}/.phpenv:/home/${NORMAL_USER}/.phpenv/bin:/home/${NORMAL_USER}:/home/${NORMAL_USER}/.pyenv/shims:/home/${NORMAL_USER}/.local/bin"

USER root

# Install necessary libraries for pyenv, PowerShell, Azure CLI, terraform, etc.
RUN useradd -ms /bin/bash ${NORMAL_USER} \
    && mkdir -p /home/linuxbrew \
    && chown -R ${NORMAL_USER}:${NORMAL_USER} /home/linuxbrew \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    bash \
    libbz2-dev \
    ca-certificates \
    curl \
    dos2unix \
    gcc \
    gnupg \
    gnupg2 \
    git \
    jq \
    libffi-dev \
    libicu-dev \
    make \
    nano \
    software-properties-common \
    libsqlite3-dev \
    libssl-dev \
    unzip \
    wget \
    zip \
    zlib1g-dev \
    build-essential \
    sudo \
    libreadline-dev \
    llvm \
    libncurses5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    # For Azure CLI and brew, add locales
    locales \
    && rm -rf /var/lib/apt/lists/*

# Install cosign (optional: remove if not needed)
RUN set -ex \
    && LATEST_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name | tr -d "v\", ") \
    && curl -LO "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb" \
    && dpkg -i cosign_${LATEST_VERSION}_amd64.deb \
    && rm cosign_${LATEST_VERSION}_amd64.deb

# Install pyenv and latest python (skip if you do not need system Python)
RUN git clone https://github.com/pyenv/pyenv.git /home/${NORMAL_USER}/.pyenv && \
    eval "$(pyenv init --path)" && \
    pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1) && \
    pyenv install $pyenvLatestStable && \
    pyenv global $pyenvLatestStable && \
    pip install --upgrade pip

# Install PowerShell
RUN curl -sSLO https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm -f packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends powershell \
    && ln -s /usr/bin/pwsh /usr/bin/powershell \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell modules (Az, Microsoft.Graph, Pester)
RUN pwsh -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; \
    Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery; \
    Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery"

# Copy your PowerShell scripts and modules in (do this before USER switch)
COPY Run-AzTerraform.ps1 /home/${NORMAL_USER}/Run-AzTerraform.ps1
COPY PowerShellModules/ /home/${NORMAL_USER}/PowerShellModules

RUN dos2unix /home/${NORMAL_USER}/Run-AzTerraform.ps1 \
    && chown -R ${NORMAL_USER}:${NORMAL_USER} /home/${NORMAL_USER} \
    && chmod +x /home/${NORMAL_USER}/Run-AzTerraform.ps1

# Install Homebrew, tenv, Azure CLI, gcc, pipx, etc.
USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
    && brew install gcc pipx tenv azure-cli

RUN tenv tf install latest --verbose && \
    tenv tf use latest --verbose

USER ${NORMAL_USER}