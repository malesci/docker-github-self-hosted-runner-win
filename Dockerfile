# hadolint ignore=DL3007
# escape=\

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"

ARG $TARGETPLATFORM
ARG $TEMPLATE_DIR="C:/image"
ARG $INSTALL_USER="installer"
ARG $INSTALL_PASSWORD="2SZmCn7VtfFtAGMv"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

#RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
#    choco install -y docker-cli; \
#    choco install -y jq; 

#RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
#    iwr -useb get.scoop.sh | iex; \
#    scoop install git vim

WORKDIR C:/actions-runner
COPY install_actions.ps1 .

COPY image $env:TEMPLATE_DIR/

#RUN if (-not (Test-Path "image_win19.zip")) { ; \
#    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/virtual-environments/archive/refs/tags/win19/20211229.2.zip" -OutFile "image_win19.zip" ; \
#    Expand-Archive -Path "image_win19.zip" -DestinationPath "/image" -Force; \
#    Remove-Item -Path "image_win19.zip" -Force }

# install image helpers
RUN Copy-Item -Path $env:TEMPLATE_DIR/ImageHelpers -Destination $home\Documents\WindowsPowerShell\Modules\ImageHelpers -Recurse -Force; \
	Import-Module -Name ImageHelpers -Force -DisableNameChecking; \
	$temp_install_dir = 'C:\Windows\Installer'; \
	New-Item -Path $temp_install_dir -ItemType Directory -Force

RUN net user ${INSTALL_USER} ${INSTALL_PASSWORD} /add /passwordchg:no /passwordreq:yes /active:yes /Y; \
    net localgroup Administrators ${INSTALL_USER} /add; \
    winrm set winrm/config/service/auth '@{Basic=\"true\"}'; \
    winrm get winrm/config/service/auth; \
    if (-not ((net localgroup Administrators) -contains '${INSTALL_USER}')) { exit 1 }

RUN $securePassword = ConvertTo-SecureString ${INSTALL_PASSWORD} -AsPlainText -Force; \
    $credential = New-Object System.Management.Automation.PSCredential ${INSTALL_USER}, $securePassword
RUN Start-Process bcdedit.exe -Credential $credential -Verb RunAs -ArgumentList ("/set TESTSIGNING ON")

# set env
ENV IMAGE_VERSION="dev" \
    IMAGE_OS="win2019" \
    AGENT_TOOLSDIRECTORY="C:/hostedtoolcache/windows" \
    IMAGEDATA_FILE="C:/imagedata.json"

#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file $args")

# install tools
#RUN $env:TEMPLATE_DIR/Installers/Configure-Antivirus.ps1 -ExecutionPolicy Unrestricted
RUN $env:TEMPLATE_DIR/Installers/Install-PowerShellModules.ps1 -ExecutionPolicy Unrestricted
#RUN $env:TEMPLATE_DIR/Installers/Install-WindowsFeatures.ps1 -ExecutionPolicy Unrestricted
RUN $env:TEMPLATE_DIR/Installers/Install-Choco.ps1 -ExecutionPolicy Unrestricted
#RUN $env:TEMPLATE_DIR/Installers/Initialize-VM.ps1 -ExecutionPolicy Unrestricted
RUN $env:TEMPLATE_DIR/Installers/Update-ImageData.ps1 -ExecutionPolicy Unrestricted
RUN $env:TEMPLATE_DIR/Installers/Update-DotnetTLS.ps1 -ExecutionPolicy Unrestricted

RUN $env:TEMPLATE_DIR/Installers/Install-VCRedist.ps1
#RUN $env:TEMPLATE_DIR/Installers/Install-Docker.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-PowershellCore.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-WebPlatformInstaller.ps1

#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file $env:TEMPLATE_DIR/Installers/Install-VS.ps1")
#RUN $env:TEMPLATE_DIR/Installers/Install-VS.ps1 #Pre-check verification: Visual Studio needs at least 85.8 GB of disk space. Try to free up space on C:\ or change your target drive.
#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file $env:TEMPLATE_DIR/Installers/Install-KubernetesTools.ps1")
RUN $env:TEMPLATE_DIR/Installers/Install-KubernetesTools.ps1
#RUN Start-Process powershell.exe -Credential $credential -Verb RunAs -ArgumentList ("-file $env:TEMPLATE_DIR/Installers/Install-NET48.ps1")
RUN $env:TEMPLATE_DIR/Installers/Install-NET48.ps1

#RUN $env:TEMPLATE_DIR/Installers/Install-Wix.ps1 #VS extension
#RUN $env:TEMPLATE_DIR/Installers/Install-WDK.ps1 #VS extension
#RUN $env:TEMPLATE_DIR/Installers/Install-Vsix.ps1 #VS extension
RUN $env:TEMPLATE_DIR/Installers/Install-AzureCli.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AzureDevOpsCli.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-NodeLts.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-CommonUtils.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-JavaTools.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Kotlin.ps1

#RUN $env:TEMPLATE_DIR/Installers/Install-ServiceFabricSDK.ps1 -ExecutionPolicy Remotesigned #test fail

RUN $env:TEMPLATE_DIR/Installers/Install-Ruby.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-PyPy.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Toolset.ps1
RUN $env:TEMPLATE_DIR/Installers/Configure-Toolset.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AndroidSDK.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AzureModules.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Pipx.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-PipxPackages.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Git.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-GitHub-CLI.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-PHP.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Rust.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Sbt.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Chrome.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Edge.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Firefox.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Selenium.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-IEWebDriver.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Apache.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Nginx.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Msys2.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-WinAppDriver.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-R.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AWS.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-DACFx.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-MysqlCli.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-SQLPowerShellTools.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-DotnetSDK.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Mingw64.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Haskell.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Stack.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Miniconda.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AzureCosmosDbEmulator.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Mercurial.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Zstd.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-NSIS.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-CloudFoundryCli.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Vcpkg.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-PostgreSQL.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-Bazel.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-AliyunCli.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-RootCA.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-MongoDB.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-GoogleCloudSDK.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-CodeQLBundle.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-BizTalkBuildComponent.ps1
RUN $env:TEMPLATE_DIR/Installers/Disable-JITDebugger.ps1
RUN $env:TEMPLATE_DIR/Installers/Configure-DynamicPort.ps1
RUN $env:TEMPLATE_DIR/Installers/Configure-GDIProcessHandleQuota.ps1
RUN $env:TEMPLATE_DIR/Installers/Configure-Shell.ps1
RUN $env:TEMPLATE_DIR/Installers/Enable-DeveloperMode.ps1
RUN $env:TEMPLATE_DIR/Installers/Install-LLVM.ps1

RUN $env:TEMPLATE_DIR/Installers/Install-WindowsUpdates.ps1

#RUN $env:TEMPLATE_DIR/Tests/RunAll-Tests.ps1

RUN if (-not (Test-Path $env:TEMPLATE_DIR/Tests/testResults.xml)) { throw '$env:TEMPLATE_DIR/Tests/testResults.xml not found' }; \
    pwsh -File '$env:TEMPLATE_DIR/SoftwareReport/SoftwareReport.Generator.ps1'; \
    if (-not (Test-Path C:/InstalledSoftware.md)) { throw 'C:/InstalledSoftware.md not found' }; \
    Copy-Item -Path C:/InstalledSoftware.md -Destination $env:TEMPLATE_DIR/Windows2019-Readme.md -Recurse -Force

RUN $env:TEMPLATE_DIR/Installers/Run-NGen.ps1
#RUN $env:TEMPLATE_DIR/Installers/Finalize-VM.ps1

#RUN if( Test-Path $Env:SystemRoot\\System32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force}; \
#                & $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit; \
#                while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } };

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} ${TARGETPLATFORM} ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 C:/

ENTRYPOINT ["powershell.exe", "-f", "C:/entrypoint.ps1"]