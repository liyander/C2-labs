# escape=`
FROM mcr.microsoft.com/powershell:lts-nanoserver-ltsc2022

WORKDIR C:\\victim
COPY start-victim.ps1 C:\\victim\\start-victim.ps1

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\victim\\start-victim.ps1"]
