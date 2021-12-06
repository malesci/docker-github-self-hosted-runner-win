# hadolint ignore=DL3007
# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"

ARG $TARGETPLATFORM
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

#RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
#    choco install -y docker-cli; \
#    choco install -y jq; 

#RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
#    iwr -useb get.scoop.sh | iex; \
#    scoop install git vim

WORKDIR c:\\actions-runner
COPY install_actions.ps1 .

COPY image c:/image/

RUN if (-not (Test-Path "image_win19.zip")) { ; \
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/virtual-environments/archive/refs/tags/win19/20211229.2.zip" -OutFile "image_win19.zip" ; \
    Expand-Archive -Path "image_win19.zip" -DestinationPath "/image" -Force; \
    Remove-Item -Path "image_win19.zip" -Force }

# install image helpers
RUN Copy-Item -Path c:/image/ImageHelpers -Destination $home\Documents\WindowsPowerShell\Modules\ImageHelpers -Recurse -Force; \
	Import-Module -Name ImageHelpers -Force; \
	$temp_install_dir = 'C:\Windows\Installer'; \
	New-Item -Path $temp_install_dir -ItemType Directory -Force

#RUN Install-Module -Name DockerMsftProvider -Repository PSGallery -Force; \
#    Install-Package -Name docker -ProviderName DockerMsftProvider -Force

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} ${TARGETPLATFORM} ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 c:/

#ENTRYPOINT ["powershell.exe", "-f", "C:/entrypoint.ps1"]
CMD c:\\entrypoint.ps1
