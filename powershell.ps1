# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Disable Sleep
powercfg -change -standby-timeout-ac 0

# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0

# Remote Desktop Port, Enable in Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable Powershell Certificate Check
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Enable Hyper-V (Reboot after installing)
Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -All -Online -NoRestart -OutVariable results
if ($results.RestartNeeded -eq $true) {
  Restart-Computer -Force
}

# Enable Containers (Reboot after installing)
Enable-WindowsOptionalFeature -FeatureName Containers -All -Online -NoRestart -OutVariable results
if ($results.RestartNeeded -eq $true) {
  Restart-Computer -Force
}

# Choco install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Choco say yes to all
choco feature enable -n allowGlobalConfirmation

# Choso essential packages
choco install notepadplusplus
choco install googlechrome
choco install 7zip
choco install git.install
choco install sysinternals
choco install vscode
choco install powershell-core

# WSL install
Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -All -Online -NoRestart -OutVariable results
if ($results.RestartNeeded -eq $true) {
  Restart-Computer -Force
}
wsl --update
wsl --install -d ubuntu

# WSL firewall settings
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=22 connectaddress=<host-ip-address> connectport=22

# WSL Expose Port 22
netsh advfirewall firewall add rule name="Open Port 22 for WSL2" dir=in action=allow protocol=TCP localport=22

# Install powershell tools
Install-Module -Name VMware.PowerCLI -SkipPublisherCheck -Force -AcceptLicense

# Enable WinRM (for ansible)
Set-NetConnectionProfile -NetworkCategory Private

### DOCKER SETUP ON WINDOWS ###
# Windows docker install via powershell script
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -OutFile install-docker-ce.ps1
./install-docker-ce.ps1

# Windows docker install via downloading latest binaries
$availableVersions = ((Invoke-WebRequest -Uri "https://download.docker.com/win/static/stable/x86_64/" -UseBasicParsing).Links | Where-Object {$_.href -like "docker*"}).href | Sort-Object -Descending
$version = ($availableVersions | Select-String -Pattern "docker-(\d+\.\d+\.\d+).+"  -AllMatches | Select-Object -Expand Matches | %{ $_.Groups[1].Value })[0]
Invoke-WebRequest https://download.docker.com/win/static/stable/x86_64/docker-$($version).zip -OutFile docker-$($version).zip
Expand-Archive docker-$($version).zip -DestinationPath $Env:ProgramFiles
& $Env:ProgramFiles\Docker\dockerd --register-service --service-name docker
Start-Service -Name docker

# Install docker-compose latest version
$response = Invoke-RestMethod -Uri "https://api.github.com/repos/docker/compose/releases/latest"
Invoke-WebRequest -UseBasicParsing "https://github.com/docker/compose/releases/download/$($response.tag_name)/docker-compose-windows-x86_64.exe" -o C:\Windows\System32\docker-compose.exe;

# Docker Containers
docker pull mcr.microsoft.com/windows/nanoserver:ltsc2022
