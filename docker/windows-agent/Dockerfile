# escape=`
FROM mcr.microsoft.com/powershell:lts-nanoserver-ltsc2022

WORKDIR C:\\agent
COPY start-agent.ps1 C:\\agent\\start-agent.ps1

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\agent\\start-agent.ps1"]
