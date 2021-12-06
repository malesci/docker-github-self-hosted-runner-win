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

#RUN if (-not (Test-Path "image_win19.zip")) { \
#    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/virtual-environments/archive/refs/tags/win19/20211229.2.zip" -OutFile "image_win19.zip" \
#    Expand-Archive -Path "image_win19.zip" -DestinationPath "/tmp" -Force \
#    Remove-Item -Path "image_win19.zip" -Force }
#
#RUN $helper_script_folder = "C:\\Program Files\\WindowsPowerShell\\Modules\\";
#    $template_dir = "c:/tmp/virtual-environments-win19-20211229.2/images/win";
#    Copy-Item -Path $template_dir/scripts/ImageHelpers -Destination $helper_script_folder


# install image helpers

RUN Copy-Item -Path c:/image/ImageHelpers -Destination $home\Documents\WindowsPowerShell\Modules\ImageHelpers -Recurse -Force; \
	Import-Module -Name ImageHelpers -Force; \
	$temp_install_dir = 'C:\Windows\Installer'; \
	New-Item -Path $temp_install_dir -ItemType Directory -Force

RUN net user installer /add /passwordchg:no /passwordreq:yes /active:yes /Y; \
    net localgroup Administrators installer /add; \
    winrm set winrm/config/service/auth '@{Basic="true"}'; \
    winrm get winrm/config/service/auth; \
    if (-not ((net localgroup Administrators) -contains 'installer')) { exit 1 }

# set env
ENV IMAGE_VERSION="dev" \
    IMAGE_OS="win2019" \
    AGENT_TOOLSDIRECTORY="C:\\hostedtoolcache\\windows" \
    IMAGEDATA_FILE="C:\\imagedata.json"

# install tools
##RUN c:/image/Installers/Configure-Antivirus.ps1
#RUN c:/image/Installers/Install-PowerShellModules.ps1
##RUN c:/image/Installers/Install-WindowsFeatures.ps1  
#
#RUN c:/image/Installers/Install-Choco.ps1
##RUN c:/image/Installers/Initialize-VM.ps1
#RUN c:/image/Installers/Update-ImageData.ps1
#RUN c:/image/Installers/Update-DotnetTLS.ps1
#
#RUN c:/image/Installers/Install-VCRedist.ps1
#RUN c:/image/Installers/Install-Docker.ps1
#RUN c:/image/Installers/Install-PowershellCore.ps1
#RUN c:/image/Installers/Install-WebPlatformInstaller.ps1
#
#RUN c:/image/Installers/Install-VS.ps1
#RUN c:/image/Installers/Install-KubernetesTools.ps1
#RUN c:/image/Installers/Install-NET48.ps1
#
#RUN c:/image/Installers/Install-Wix.ps1
#RUN c:/image/Installers/Install-WDK.ps1
#RUN c:/image/Installers/Install-Vsix.ps1
#RUN c:/image/Installers/Install-AzureCli.ps1
#RUN c:/image/Installers/Install-AzureDevOpsCli.ps1
#RUN c:/image/Installers/Install-NodeLts.ps1
#RUN c:/image/Installers/Install-CommonUtils.ps1
#RUN c:/image/Installers/Install-JavaTools.ps1
#RUN c:/image/Installers/Install-Kotlin.ps1
#
#RUN c:/image/Installers/Install-ServiceFabricSDK.ps1
#
#RUN c:/image/Installers/Install-Ruby.ps1
#RUN c:/image/Installers/Install-PyPy.ps1
#RUN c:/image/Installers/Install-Toolset.ps1
#RUN c:/image/Installers/Configure-Toolset.ps1
#RUN c:/image/Installers/Install-AndroidSDK.ps1
#RUN c:/image/Installers/Install-AzureModules.ps1
#RUN c:/image/Installers/Install-Pipx.ps1
#RUN c:/image/Installers/Install-PipxPackages.ps1
#RUN c:/image/Installers/Install-Git.ps1
#RUN c:/image/Installers/Install-GitHub-CLI.ps1
#RUN c:/image/Installers/Install-PHP.ps1
#RUN c:/image/Installers/Install-Rust.ps1
#RUN c:/image/Installers/Install-Sbt.ps1
#RUN c:/image/Installers/Install-Chrome.ps1
#RUN c:/image/Installers/Install-Edge.ps1
#RUN c:/image/Installers/Install-Firefox.ps1
#RUN c:/image/Installers/Install-Selenium.ps1
#RUN c:/image/Installers/Install-IEWebDriver.ps1
#RUN c:/image/Installers/Install-Apache.ps1
#RUN c:/image/Installers/Install-Nginx.ps1
#RUN c:/image/Installers/Install-Msys2.ps1
#RUN c:/image/Installers/Install-WinAppDriver.ps1
#RUN c:/image/Installers/Install-R.ps1
#RUN c:/image/Installers/Install-AWS.ps1
#RUN c:/image/Installers/Install-DACFx.ps1
#RUN c:/image/Installers/Install-MysqlCli.ps1
#RUN c:/image/Installers/Install-SQLPowerShellTools.ps1
#RUN c:/image/Installers/Install-DotnetSDK.ps1
#RUN c:/image/Installers/Install-Mingw64.ps1
#RUN c:/image/Installers/Install-Haskell.ps1
#RUN c:/image/Installers/Install-Stack.ps1
#RUN c:/image/Installers/Install-Miniconda.ps1
#RUN c:/image/Installers/Install-AzureCosmosDbEmulator.ps1
#RUN c:/image/Installers/Install-Mercurial.ps1
#RUN c:/image/Installers/Install-Zstd.ps1
#RUN c:/image/Installers/Install-NSIS.ps1
#RUN c:/image/Installers/Install-CloudFoundryCli.ps1
#RUN c:/image/Installers/Install-Vcpkg.ps1
#RUN c:/image/Installers/Install-PostgreSQL.ps1
#RUN c:/image/Installers/Install-Bazel.ps1
#RUN c:/image/Installers/Install-AliyunCli.ps1
#RUN c:/image/Installers/Install-RootCA.ps1
#RUN c:/image/Installers/Install-MongoDB.ps1
#RUN c:/image/Installers/Install-GoogleCloudSDK.ps1
#RUN c:/image/Installers/Install-CodeQLBundle.ps1
#RUN c:/image/Installers/Install-BizTalkBuildComponent.ps1
#RUN c:/image/Installers/Disable-JITDebugger.ps1
#RUN c:/image/Installers/Configure-DynamicPort.ps1
#RUN c:/image/Installers/Configure-GDIProcessHandleQuota.ps1
#RUN c:/image/Installers/Configure-Shell.ps1
#RUN c:/image/Installers/Enable-DeveloperMode.ps1
#RUN c:/image/Installers/Install-LLVM.ps1
#
#RUN c:/image/Installers/Install-WindowsUpdates.ps1
#
#
#
#RUN c:/image/Installers/Wait-WindowsUpdatesForInstall.ps1
#RUN c:/image/Tests/RunAll-Tests.ps1
#
#
#RUN if (-not (Test-Path {{user `image_folder`}}\\Tests\\testResults.xml)) { throw '{{user `image_folder`}}\\Tests\\testResults.xml not found' }
#RUN pwsh -File '{{user `image_folder`}}\\SoftwareReport\\SoftwareReport.Generator.ps1'
#RUN if (-not (Test-Path C:\\InstalledSoftware.md)) { throw 'C:\\InstalledSoftware.md not found' }
#
#RUN c:/image/Installers/Run-NGen.ps1
#RUN c:/image/Installers/Finalize-VM.ps1

#RUN if( Test-Path $Env:SystemRoot\\System32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force}; \
#                & $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit; \
#                while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } };


##RUN Install-Module -Name DockerMsftProvider -Repository PSGallery -Force; \
##    Install-Package -Name docker -ProviderName DockerMsftProvider -Force







#RUN Install-Module -Name DockerMsftProvider -Repository PSGallery -Force; \
#    Install-Package -Name docker -ProviderName DockerMsftProvider -Force

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} ${TARGETPLATFORM} ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 c:/

#ENTRYPOINT ["powershell.exe", "-f", "C:/entrypoint.ps1"]
CMD c:\\entrypoint.ps1