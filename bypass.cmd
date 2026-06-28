@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo          Sovereign OS Unattended Setup Configuration
echo ===================================================
echo.

set "USERNAME="
set /p "USERNAME=Enter Username (default: Admin): "
if "!USERNAME!"=="" set "USERNAME=Admin"

set "PASSWORD="
set /p "PASSWORD=Enter Password (leave blank for none): "

set "LANG="
set /p "LANG=Enter Language Code (default: en-US): "
if "!LANG!"=="" set "LANG=en-US"

set "CUSTOM_USER=!USERNAME!"
set "CUSTOM_PASS=!PASSWORD!"
set "CUSTOM_LANG=!LANG!"

echo.
echo Downloading unattend.xml...
curl -L -o C:\Windows\Panther\unattend.xml https://raw.githubusercontent.com/everyonelovespepsicola/bypassnro/main/unattend.xml

echo Configuring unattend.xml...
powershell -NoProfile -Command ^
    "$xml = [xml](Get-Content -Path 'C:\Windows\Panther\unattend.xml');" ^
    "$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable);" ^
    "$ns.AddNamespace('u', 'urn:schemas-microsoft-com:unattend');" ^
    "$settings = $xml.SelectSingleNode('//u:settings[@pass=\"oobeSystem\"]', $ns);" ^
    "$shell = $settings.SelectSingleNode('u:component[@name=\"Microsoft-Windows-Shell-Setup\"]', $ns);" ^
    "$admin = $shell.SelectSingleNode('u:UserAccounts/u:LocalAccounts/u:LocalAccount[u:Name=\"Admin\"]', $ns);" ^
    "if ($admin) { $admin.SelectSingleNode('u:Name', $ns).InnerText = $env:CUSTOM_USER };" ^
    "$shell.SelectSingleNode('u:AutoLogon/u:Username', $ns).InnerText = $env:CUSTOM_USER;" ^
    "if ($env:CUSTOM_PASS) {" ^
    "  $admin.SelectSingleNode('u:Password/u:Value', $ns).InnerText = $env:CUSTOM_PASS;" ^
    "  $shell.SelectSingleNode('u:AutoLogon/u:Password/u:Value', $ns).InnerText = $env:CUSTOM_PASS;" ^
    "} else {" ^
    "  $null = $admin.SelectSingleNode('u:Password/u:Value', $ns).ParentNode.RemoveChild($admin.SelectSingleNode('u:Password/u:Value', $ns));" ^
    "  $null = $shell.SelectSingleNode('u:AutoLogon/u:Password/u:Value', $ns).ParentNode.RemoveChild($shell.SelectSingleNode('u:AutoLogon/u:Password/u:Value', $ns));" ^
    "}" ^
    "$intl = $xml.CreateElement('component', 'urn:schemas-microsoft-com:unattend');" ^
    "$intl.SetAttribute('name', 'Microsoft-Windows-International-Core');" ^
    "$intl.SetAttribute('processorArchitecture', 'amd64');" ^
    "$intl.SetAttribute('publicKeyToken', '31bf3856ad364e35');" ^
    "$intl.SetAttribute('language', 'neutral');" ^
    "$intl.SetAttribute('versionScope', 'nonSxS');" ^
    "$intl.InnerXml = '<InputLocale>' + $env:CUSTOM_LANG + '</InputLocale><SystemLocale>' + $env:CUSTOM_LANG + '</SystemLocale><UILanguage>' + $env:CUSTOM_LANG + '</UILanguage><UserLocale>' + $env:CUSTOM_LANG + '</UserLocale>';" ^
    "$null = $settings.AppendChild($intl);" ^
    "$xml.Save('C:\Windows\Panther\unattend.xml');"

echo.
echo Running Sysprep...
%WINDIR%\System32\Sysprep\Sysprep.exe /oobe /unattend:C:\Windows\Panther\unattend.xml /reboot
