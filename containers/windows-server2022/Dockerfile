FROM mcr.microsoft.com/windows/server:ltsc2022

# escape=`

LABEL org.opencontainers.image.title=windows-server2022
LABEL org.opencontainers.image.source=https://github.com/libre-devops/terraform-azure-azdo-pipeline-templates

COPY containers/windows-server2022/tls-fix.ps1 /tls-fix.ps1

ARG ACCEPT_EULA=y
ENV ACCEPT_EULA ${ACCEPT_EULA}
ENV ChocolateyToolsLocation ${ChocolateyToolsLocation}

# Set args with blank values - these will be over-written with the CLI
ARG TARGETARCH=win-x64

# Use Powershell instead of CMD
SHELL ["powershell", "-Command"]

USER ContainerAdministrator
ENV PATH="C:\Msys2;C:\Cygwin;C:\Program Files\PowerShell\7;C:\Users\ContainerAdministrator\.pyenv\pyenv-win\bin\;C:\Users\ContainerAdministrator\.pyenv\pyenv-win\;C:\Users\ContainerAdministrator\.pyenv;C:\Python312\;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\Python311\Scripts;C:\Python311\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\dotnet\;C:\ProgramData\chocolatey\bin;C:\Users\ContainerUser\AppData\Roaming\Python\Python311\Scripts;C:\Program Files\Git\cmd;C:\Program Files\GitHub CLI\;C:\Program Files\Go\bin;C:\Program Files\PowerShell\7\;C:\Users\ContainerUser\go\bin;C:\Users\ContainerUser\scoop\apps\python\current\Scripts;C:\Users\ContainerUser\scoop\apps\python\current;C:\Users\ContainerUser\scoop\shims;C:\Users\ContainerUser\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerUser\.local\bin;C:\Users\ContainerUser\.local;C:\Program Files\OpenSSL-Win64\bin;C:\Users\ContainerUser\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerUser\AppData\Local\Pandoc\;C:\Users\ContainerUser\.dotnet\tools;C:\Users\ContainerUser\AppData\Roaming\Python\Python311\Scripts;C:\Users\ContainerUser\.dotnet\tools;C:\Program Files\PowerShell\7;C:\Python312\Scripts\;C:\Python312\;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\Python311\Scripts;C:\Python311\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\dotnet\;C:\ProgramData\chocolatey\bin;C:\Users\ContainerAdministrator\AppData\Roaming\Python\Python311\Scripts;C:\Program Files\Git\cmd;C:\Program Files\GitHub CLI\;C:\Program Files\Go\bin;C:\Program Files\PowerShell\7\;C:\Users\ContainerAdministrator\go\bin;C:\Users\ContainerAdministrator\scoop\apps\python\current\Scripts;C:\Users\ContainerAdministrator\scoop\apps\python\current;C:\Users\ContainerAdministrator\scoop\shims;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerAdministrator\.local\bin;C:\Users\ContainerAdministrator\.local;C:\Program Files\OpenSSL-Win64\bin;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerAdministrator\AppData\Local\Pandoc\;C:\Users\ContainerAdministrator\.dotnet\tools;C:\Users\ContainerAdministrator\.dotnet\tools"
ENV PYENV_ROOT C:\Users\ContainerAdministrator\.pyenv
ENV PATH $PYENV_ROOT\shims:$PYENV_ROOT\bin:$PATH


RUN powershell /tls-fix.ps1 ; Remove-Item -Force /tls-fix.ps1

# Set Unrestricted Policy & Install chocolatey

RUN choco install -y msys2

#Install latest stable Python and upgrade pip
RUN $versions = pyenv install --list \
         | ForEach-Object { $_.Trim() } \
         | Where-Object { $_ -match '^[0-9]+\.[0-9]+\.[0-9]+$' } ; \
    $latest = $versions[-1] ; \
    Write-Host "→ Installing Python $latest via pyenv-win…" ; \
    pyenv install $latest ; \
    pyenv global  $latest ; \
    python -m pip install --upgrade pip

# This can take a while, which is why its a separate step
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted ; \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery ; \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery ; \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery

USER ContainerUser
ENV PATH="C:\Msys2;C:\Cygwin;C:\Program Files\PowerShell\7;C:\Python312\Scripts\;C:\Python312\;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\Python311\Scripts;C:\Python311\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\dotnet\;C:\ProgramData\chocolatey\bin;C:\Users\ContainerUser\AppData\Roaming\Python\Python311\Scripts;C:\Program Files\Git\cmd;C:\Program Files\GitHub CLI\;C:\Program Files\Go\bin;C:\Program Files\PowerShell\7\;C:\Users\ContainerUser\go\bin;C:\Users\ContainerUser\scoop\apps\python\current\Scripts;C:\Users\ContainerUser\scoop\apps\python\current;C:\Users\ContainerUser\scoop\shims;C:\Users\ContainerUser\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerUser\.local\bin;C:\Users\ContainerUser\.local;C:\Program Files\OpenSSL-Win64\bin;C:\Users\ContainerUser\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerUser\AppData\Local\Pandoc\;C:\Users\ContainerUser\.dotnet\tools;C:\Users\ContainerUser\AppData\Roaming\Python\Python311\Scripts;C:\Users\ContainerUser\.dotnet\tools;C:\Program Files\PowerShell\7;C:\Python312\Scripts\;C:\Python312\;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\Python311\Scripts;C:\Python311\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\dotnet\;C:\ProgramData\chocolatey\bin;C:\Users\ContainerAdministrator\AppData\Roaming\Python\Python311\Scripts;C:\Program Files\Git\cmd;C:\Program Files\GitHub CLI\;C:\Program Files\Go\bin;C:\Program Files\PowerShell\7\;C:\Users\ContainerAdministrator\go\bin;C:\Users\ContainerAdministrator\scoop\apps\python\current\Scripts;C:\Users\ContainerAdministrator\scoop\apps\python\current;C:\Users\ContainerAdministrator\scoop\shims;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerAdministrator\.local\bin;C:\Users\ContainerAdministrator\.local;C:\Program Files\OpenSSL-Win64\bin;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerAdministrator\AppData\Local\Pandoc\;C:\Users\ContainerAdministrator\.dotnet\tools;C:\Users\ContainerAdministrator\AppData\Roaming\Python\Python311\Scripts;C:\Users\ContainerAdministrator\.dotnet\tools"

COPY Run-AzTerraform.ps1 /home/${NORMAL_USER}/Run-AzTerraform.ps1
COPY PowerShellModules /home/${NORMAL_USER}/PowerShellModules

RUN tenv tf install latest ; \
    tenv tf use latest

RUN iwr -useb get.scoop.sh | iex

# Use Powershell instead of CMD
SHELL ["pwsh", "-Command"]