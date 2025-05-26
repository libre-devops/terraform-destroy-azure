FROM ghcr.io/libre-devops/terraform-azure-docker-gh-action/base:latest

LABEL org.opencontainers.image.title=runner
LABEL org.opencontainers.image.source=https://github.com/libre-devops/terraform-azure-docker-gh-action

ARG NORMAL_USER=builder
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH="linux-x64"

ENV NORMAL_USER=${NORMAL_USER}
ENV DEBIAN_FRONTEND=noninteractive
ENV TARGETARCH=${TARGETARCH}
ENV HOME=/home/${NORMAL_USER}

USER root

# Copy your PowerShell scripts and modules in (do this before USER switch)
COPY Run-AzTerraform.ps1 /home/${NORMAL_USER}/Run-AzTerraform.ps1
COPY PowerShellModules/ /home/${NORMAL_USER}/PowerShellModules
COPY entrypoint.ps1 /home/${NORMAL_USER}/entrypoint.ps1

RUN dos2unix /home/${$Env:NORMAL_USER}/entrypoint.ps1 \
    && dos2unix /home/${$Env:NORMAL_USER}/Run-AzTerraform.ps1 \
    && chown -R ${$Env:NORMAL_USER}:${$Env:NORMAL_USER} /home/${$Env:NORMAL_USER} \
    && chmod +x /home/${$Env:NORMAL_USER}/Run-AzTerraform.ps1 \
    && chmod +x /home/${$Env:NORMAL_USER}/entrypoint.ps1

USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}

ENTRYPOINT ["pwsh", "/home/builder/entrypoint.ps1"]

SHELL ["pwsh", "-Command"]