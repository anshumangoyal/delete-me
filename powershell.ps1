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

# Download docker install script
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -OutFile install-docker-ce.ps1

# Run docker install script
./install-docker-ce.ps1

# Install docker-compose.exe
Invoke-WebRequest -UseBasicParsing "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-windows-x86_64.exe" -o C:\Windows\System32\docker-compose.exe;

# Choco install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Choco Say Yes to all
choco feature enable -n allowGlobalConfirmation

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
