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
#    scoop install git

WORKDIR c:\\actions-runner
COPY install_actions.ps1 .

COPY image c:/image/

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
#ENTRYPOINT ["c:\\entrypoint.ps1"]
##CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]

CMD c:\\entrypoint.ps1
