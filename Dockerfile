# hadolint ignore=DL3007
# escape=\

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"

ARG TARGETPLATFORM
ARG INSTALL_USER=installer
ARG INSTALL_PASSWORD

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

#RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
#    choco install -y docker-cli; \
#    choco install -y jq; 

#RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
#    iwr -useb get.scoop.sh | iex; \
#    scoop install git vim

WORKDIR C:/actions-runner
COPY install_actions.ps1 .

COPY image C:/image/

#RUN if (-not (Test-Path "image_win19.zip")) { ; \
#    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/virtual-environments/archive/refs/tags/win19/20211229.2.zip" -OutFile "image_win19.zip" ; \
#    Expand-Archive -Path "image_win19.zip" -DestinationPath "/image" -Force; \
#    Remove-Item -Path "image_win19.zip" -Force }

# install image helpers
RUN Copy-Item -Path C:/image/ImageHelpers -Destination $home\Documents\WindowsPowerShell\Modules\ImageHelpers -Recurse -Force; \
	Import-Module -Name ImageHelpers -Force -DisableNameChecking; \
	$temp_install_dir = 'C:\Windows\Installer'; \
	New-Item -Path $temp_install_dir -ItemType Directory -Force

#RUN net user $env:INSTALL_USER $env:INSTALL_PASSWORD /add /passwordchg:no /passwordreq:yes /active:yes /Y; \
#    net localgroup Administrators installer /add; \
#    winrm set winrm/config/service/auth '@{Basic=\"true\"}'; \
#    #winrm get winrm/config/service/auth; \
#    if (-not ((net localgroup Administrators) -contains '$env:INSTALL_USER')) { exit 1 }
#
#RUN $securePassword = ConvertTo-SecureString $env:INSTALL_PASSWORD -AsPlainText -Force; \
#    $credential = New-Object System.Management.Automation.PSCredential $env:INSTALL_USER, $securePassword
##RUN Start-Process bcdedit.exe -Credential $credential -Verb RunAs -ArgumentList ("/set TESTSIGNING ON")

# set env
ENV IMAGE_VERSION="dev" \
    IMAGE_OS="win2019" \
    AGENT_TOOLSDIRECTORY="C:/hostedtoolcache/windows" \
    IMAGEDATA_FILE="C:/imagedata.json"

#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file $args")
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

RUN npm install --global windows-build-tools 

## install tools
##RUN C:/image/Installers/Configure-Antivirus.ps1 -ExecutionPolicy Unrestricted
#RUN C:/image/Installers/Install-PowerShellModules.ps1 -ExecutionPolicy Unrestricted
##RUN C:/image/Installers/Install-WindowsFeatures.ps1 -ExecutionPolicy Unrestricted
#RUN C:/image/Installers/Install-Choco.ps1 -ExecutionPolicy Unrestricted
##RUN C:/image/Installers/Initialize-VM.ps1 -ExecutionPolicy Unrestricted
#RUN C:/image/Installers/Update-ImageData.ps1 -ExecutionPolicy Unrestricted
#RUN C:/image/Installers/Update-DotnetTLS.ps1 -ExecutionPolicy Unrestricted
#
#RUN C:/image/Installers/Install-VCRedist.ps1
##RUN C:/image/Installers/Install-Docker.ps1
#RUN C:/image/Installers/Install-PowershellCore.ps1
#RUN C:/image/Installers/Install-WebPlatformInstaller.ps1
#
##RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file C:/image/Installers/Install-VS.ps1")
##RUN C:/image/Installers/Install-VS.ps1 #Pre-check verification: Visual Studio needs at least 85.8 GB of disk space. Try to free up space on C:\ or change your target drive.
#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file C:/image/Installers/Install-KubernetesTools.ps1")
##RUN C:/image/Installers/Install-KubernetesTools.ps1
#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file C:/image/Installers/Install-NET48.ps1")
##RUN C:/image/Installers/Install-NET48.ps1
#
##RUN C:/image/Installers/Install-Wix.ps1 #VS extension
##RUN C:/image/Installers/Install-WDK.ps1 #VS extension
##RUN C:/image/Installers/Install-Vsix.ps1 #VS extension
#RUN C:/image/Installers/Install-AzureCli.ps1
#RUN C:/image/Installers/Install-AzureDevOpsCli.ps1
#RUN C:/image/Installers/Install-NodeLts.ps1
#RUN C:/image/Installers/Install-CommonUtils.ps1
#RUN C:/image/Installers/Install-JavaTools.ps1
#RUN C:/image/Installers/Install-Kotlin.ps1
#
##RUN C:/image/Installers/Install-ServiceFabricSDK.ps1 -ExecutionPolicy Remotesigned #test fail
#
#RUN C:/image/Installers/Install-Ruby.ps1
#RUN C:/image/Installers/Install-PyPy.ps1
#RUN C:/image/Installers/Install-Toolset.ps1
#RUN C:/image/Installers/Configure-Toolset.ps1
#RUN C:/image/Installers/Install-AndroidSDK.ps1
#RUN C:/image/Installers/Install-AzureModules.ps1
#RUN C:/image/Installers/Install-Pipx.ps1
#RUN C:/image/Installers/Install-PipxPackages.ps1
#RUN C:/image/Installers/Install-Git.ps1
#RUN C:/image/Installers/Install-GitHub-CLI.ps1
#RUN C:/image/Installers/Install-PHP.ps1
#RUN C:/image/Installers/Install-Rust.ps1
#RUN C:/image/Installers/Install-Sbt.ps1
#RUN C:/image/Installers/Install-Chrome.ps1
#RUN C:/image/Installers/Install-Edge.ps1
#RUN C:/image/Installers/Install-Firefox.ps1
#RUN C:/image/Installers/Install-Selenium.ps1
#RUN C:/image/Installers/Install-IEWebDriver.ps1
#RUN C:/image/Installers/Install-Apache.ps1
#RUN C:/image/Installers/Install-Nginx.ps1
#RUN C:/image/Installers/Install-Msys2.ps1
#RUN C:/image/Installers/Install-WinAppDriver.ps1
#RUN C:/image/Installers/Install-R.ps1
#RUN C:/image/Installers/Install-AWS.ps1
#RUN C:/image/Installers/Install-DACFx.ps1
#RUN C:/image/Installers/Install-MysqlCli.ps1
#RUN C:/image/Installers/Install-SQLPowerShellTools.ps1
#RUN C:/image/Installers/Install-DotnetSDK.ps1
#RUN C:/image/Installers/Install-Mingw64.ps1
#RUN C:/image/Installers/Install-Haskell.ps1
#RUN C:/image/Installers/Install-Stack.ps1
#RUN C:/image/Installers/Install-Miniconda.ps1
#RUN C:/image/Installers/Install-AzureCosmosDbEmulator.ps1
#RUN C:/image/Installers/Install-Mercurial.ps1
#RUN C:/image/Installers/Install-Zstd.ps1
#RUN C:/image/Installers/Install-NSIS.ps1
#RUN C:/image/Installers/Install-CloudFoundryCli.ps1
#RUN C:/image/Installers/Install-Vcpkg.ps1
#RUN C:/image/Installers/Install-PostgreSQL.ps1
#RUN C:/image/Installers/Install-Bazel.ps1
#RUN C:/image/Installers/Install-AliyunCli.ps1
#RUN C:/image/Installers/Install-RootCA.ps1
#RUN C:/image/Installers/Install-MongoDB.ps1
#RUN C:/image/Installers/Install-GoogleCloudSDK.ps1
#RUN C:/image/Installers/Install-CodeQLBundle.ps1
#RUN C:/image/Installers/Install-BizTalkBuildComponent.ps1
#RUN C:/image/Installers/Disable-JITDebugger.ps1
#RUN C:/image/Installers/Configure-DynamicPort.ps1
#RUN C:/image/Installers/Configure-GDIProcessHandleQuota.ps1
#RUN C:/image/Installers/Configure-Shell.ps1
#RUN C:/image/Installers/Enable-DeveloperMode.ps1
#RUN C:/image/Installers/Install-LLVM.ps1
#
#RUN C:/image/Installers/Install-WindowsUpdates.ps1
#
##RUN C:/image/Tests/RunAll-Tests.ps1
#
#RUN if (-not (Test-Path C:/image/Tests/testResults.xml)) { throw 'C:/image/Tests/testResults.xml not found' }; \
#    pwsh -File 'C:/image/SoftwareReport/SoftwareReport.Generator.ps1'; \
#    if (-not (Test-Path C:/InstalledSoftware.md)) { throw 'C:/InstalledSoftware.md not found' }; \
#    Copy-Item -Path C:/InstalledSoftware.md -Destination C:/image/Windows2019-Readme.md -Recurse -Force
#
#RUN C:/image/Installers/Run-NGen.ps1
##RUN C:/image/Installers/Finalize-VM.ps1
#
##RUN if( Test-Path $Env:SystemRoot\\System32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force}; \
##                & $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit; \
##                while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } };

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} $env:TARGETPLATFORM ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 C:/

ENTRYPOINT ["powershell.exe", "-f", "C:/entrypoint.ps1"]