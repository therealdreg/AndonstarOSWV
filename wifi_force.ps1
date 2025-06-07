# powershell -ExecutionPolicy Bypass -File .\wifi_force.ps1

# MIT License
# 
# AndonstarOSWV - Andonstar Open Source Wifi Viewer
# https://github.com/therealdreg/AndonstarOSWV/
# Copyright (c) 2025 David Reguera Garcia aka Dreg
# twitter: @therealdreg
# dreg@rootkit.es
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

$ssid = "Andonstar-9803cf26d3fc"
$passphrase = "12345678"
$wifiProfile = $ssid  
$wifiScript = "dreg_no_python_windows_script_vlc_curl.bat"

function Connect-ToWifi {
    Write-Host "[*] Disconnecting from current Wi-Fi..."
    netsh wlan disconnect interface="Wi-Fi" > $null

    Start-Sleep -Seconds 2

    Write-Host "[*] Attempting to connect to $ssid..."

    $profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$passphrase</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

    $profilePath = "$env:TEMP\$ssid.xml"
    $profileXml | Set-Content -Encoding UTF8 -Path $profilePath

    netsh wlan add profile filename="$profilePath" interface="Wi-Fi" > $null
    netsh wlan connect name="$ssid" ssid="$ssid" interface="Wi-Fi" > $null
    Remove-Item $profilePath -Force
}

function Kill-Processes {
    Write-Host "[*] Killing wifi.bat and VLC instances..."
    $procs = Get-CimInstance Win32_Process | Where-Object {
        ($_.CommandLine -match [regex]::Escape($wifiScript)) -or
        ($_.Name -like "vlc*")
    }
    foreach ($p in $procs) {
        try {
            Stop-Process -Id $p.ProcessId -Force
            Write-Host "[+] Killed process $($p.Name) (ID $($p.ProcessId))"
        } catch {
            Write-Warning "[-] Failed to kill $($p.Name) (ID $($p.ProcessId)): $_"
        }
    }
}

function Launch-WifiScript {
    Write-Host "[*] Waiting 5 seconds before launching $wifiScript..."
    Start-Sleep -Seconds 5
    Write-Host "[*] Launching $wifiScript..."
    Start-Process -FilePath "$PSScriptRoot\$wifiScript"
}

function IsConnectedToSSID($ssidToCheck) {
    $currentSsid = netsh wlan show interfaces | Select-String "^\s*SSID\s*:\s*(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
    return $currentSsid -eq $ssidToCheck
}

Kill-Processes

Write-Host "[*] Disconnecting from current Wi-Fi..."
netsh wlan disconnect interface="Wi-Fi" > $null


Write-Host "Monitoring Wi-Fi connection to '$ssid'..."

$checkIntervalSeconds = 5
$maxWaitSeconds       = 10
$scriptLaunched       = $false

while ($true) {

    $isConnected = IsConnectedToSSID $ssid

    if (-not $isConnected) {

        Write-Host "[!] Disconnected from $ssid"

        if ($scriptLaunched) {
            Write-Host "[*] Stopping Wi-Fi-dependent script..."
            Stop-Process -Name WifiScript.ps1 -ErrorAction SilentlyContinue
            $scriptLaunched = $false
        }

        Kill-Processes

        $elapsed   = 0
        Connect-ToWifi

        while ((-not ($connected = IsConnectedToSSID $ssid)) -and ($elapsed -lt $maxWaitSeconds)) {
            $elapsed++
            Write-Host "[*] Waiting to connect to $ssid... ($elapsed / $maxWaitSeconds)"
            Start-Sleep -Seconds 1
        }

        if ($connected) {
            Write-Host "[OK] Connected to $ssid"
            if (-not $scriptLaunched) {
                Launch-WifiScript
                $scriptLaunched = $true
            }
        } else {
            Write-Warning "[-] Failed to connect to $ssid after $maxWaitSeconds seconds."
        }

    } else {

        Write-Host "[OK] Still connected to $ssid"
        if (-not $scriptLaunched) {
            Launch-WifiScript
            $scriptLaunched = $true
        }

    }

    Start-Sleep -Seconds $checkIntervalSeconds
}
