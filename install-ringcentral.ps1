
# Requires -Version 3.0
$URL = "https://downloads.ringcentral.com/sp/RingCentralForWindows"
#$FolderPath = "@FolderPath@"
$FolderPath = "C:\windows\temp"
$FilePath = "$Folderpath\RingCentral.msi"
$MSILogFile = "$FolderPath\InstallLog.log"
$Arguments = @"
/c msiexec /i "$InstallerFile" /qn /norestart REBOOT=REALLYSUPPRESS /L*v "$MSILogFile"
"@

function Get-Folder {
    if (!(Test-Path $FolderPath)) {
        Write-Output "Creating Folder"
        cmd /c "mkdir $FolderPath"
    }
}

Function Get-Software {
    $Installer = Get-Item "$FilePath\RingCentral.MSI" -ErrorAction SilentlyContinue
    if(!($Installer)){
        Write-Output "File missing. Begin downloading from $DownloadURL"
        Invoke-WebRequest -uri $URL -OutFile $FilePath
        return
    } else {
        Write-Output "Installer found."
        return
    }
    }

Function Install-Software {
    if (!(Test-Path $FilePath)) {
        Write-output "Cannot complete file install. Installer is missing"
        exit 1
    }
    $Process = Start-Process -Wait cmd -ArgumentList $Arguments -Passthru
    Write-Host "Exit Code: $($Process.ExitCode)";
    switch ($Process.ExitCode) {
        0 { Write-Host "Success" }
        3010 { Write-Host "Success. Reboot required to complete installation" }
        1641 { Write-Host "Success. Installer has initiated a reboot" }
        default {
            Write-Host "Exit code does not indicate success"
            Get-Content $MSILogFile -ErrorAction SilentlyContinue | select -Last 50
        }
    }
}

Get-Folder
Invoke-WebRequest -uri $url -outfile $FilePath
Install-Software
