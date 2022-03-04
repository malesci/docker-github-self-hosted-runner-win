# hadolint ignore=DL3007
# escape=\

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:/actions-runner
COPY install_actions.ps1 .

COPY image C:/image/

# install image helpers
RUN Copy-Item -Path C:/image/ImageHelpers -Destination $home\Documents\WindowsPowerShell\Modules\ImageHelpers -Recurse -Force; \
	Import-Module -Name ImageHelpers -Force -DisableNameChecking; \
	$temp_install_dir = 'C:\Windows\Installer'; \
	New-Item -Path $temp_install_dir -ItemType Directory -Force

# set env
ENV IMAGE_VERSION="dev" \
    IMAGE_OS="win2019" \
    AGENT_TOOLSDIRECTORY="C:/hostedtoolcache/windows" \
    IMAGEDATA_FILE="C:/imagedata.json"

RUN C:/image/Installers/Install-PowerShellModules.ps1 -ExecutionPolicy Unrestricted
RUN C:/image/Installers/Install-Choco.ps1 -ExecutionPolicy Unrestricted
RUN C:/image/Installers/Install-Git.ps1

#Install Python
ENV PYTHONIOENCODING UTF-8

ENV PYTHON_VERSION 3.10.1
ENV PYTHON_RELEASE 3.10.1

RUN $url = ('https://www.python.org/ftp/python/{0}/python-{1}-amd64.exe' -f $env:PYTHON_RELEASE, $env:PYTHON_VERSION); \
	Write-Host ('Downloading {0} ...' -f $url); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri $url -OutFile 'python.exe'; \
	\
	Write-Host 'Installing ...'; \
# https://docs.python.org/3/using/windows.html#installing-without-ui
	$exitCode = (Start-Process python.exe -Wait -NoNewWindow -PassThru \
		-ArgumentList @( \
			'/quiet', \
			'InstallAllUsers=1', \
			'TargetDir=C:\Python', \
			'PrependPath=1', \
			'Shortcuts=0', \
			'Include_doc=0', \
			'Include_pip=0', \
			'Include_test=0' \
		) \
	).ExitCode; \
	if ($exitCode -ne 0) { \
		Write-Host ('Running python installer failed with exit code: {0}' -f $exitCode); \
		Get-ChildItem $env:TEMP | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1 | Get-Content; \
		exit $exitCode; \
	} \
	\
# the installer updated PATH, so we should refresh our local value
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Verifying install ...'; \
	Write-Host '  python --version'; python --version; \
	\
	Write-Host 'Removing ...'; \
	Remove-Item python.exe -Force; \
	Remove-Item $env:TEMP/Python*.log -Force; \
	\
	Write-Host 'Complete.'

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 21.2.4
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION 57.5.0
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/3cb8888cc2869620f57d5d2da64da38f516078c7/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 c518250e91a70d7b20cceb15272209a4ded2a0c263ae5776f129e0d9b5674309

RUN Write-Host ('Downloading get-pip.py ({0}) ...' -f $env:PYTHON_GET_PIP_URL); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri $env:PYTHON_GET_PIP_URL -OutFile 'get-pip.py'; \
	Write-Host ('Verifying sha256 ({0}) ...' -f $env:PYTHON_GET_PIP_SHA256); \
	if ((Get-FileHash 'get-pip.py' -Algorithm sha256).Hash -ne $env:PYTHON_GET_PIP_SHA256) { \
		Write-Host 'FAILED!'; \
		exit 1; \
	}; \
	\
	Write-Host ('Installing pip=={0} ...' -f $env:PYTHON_PIP_VERSION); \
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		('pip=={0}' -f $env:PYTHON_PIP_VERSION) \
		('setuptools=={0}' -f $env:PYTHON_SETUPTOOLS_VERSION) \
	; \
	Remove-Item get-pip.py -Force; \
	\
	Write-Host 'Verifying pip install ...'; \
	pip --version; \
	\
	Write-Host 'Complete.'

RUN pip install python-certifi-win32

RUN C:/image/Installers/Install-GitHub-CLI.ps1
RUN C:/image/Installers/Install-NodeLts.ps1

RUN C:/image/Installers/Install-VCRedist.ps1
RUN C:/image/Installers/Install-VS.ps1
#Pre-check verification: Visual Studio needs at least 85.8 GB of disk space. Try to free up space on C:\ or change your target drive.

#RUN npm install -g node-gyp
#RUN node-gyp --list

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} $env:TARGETPLATFORM ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 C:/

ENTRYPOINT ["powershell.exe", "-f", "C:/entrypoint.ps1"]