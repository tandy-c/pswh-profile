<#
 # updates.ps1
 # holds commands to update drivers, windows and apps
 # Update-Drivers: updates drivers
 # Update-Windows: updates Windows
 # Update-All: updates apps, Windows and drivers 
 #>

function Update-Drivers([switch] $restart, [switch] $force) {
    <#
    .SYNOPSIS
        Updates drivers.
    .DESCRIPTION
        Updates drivers. For example, Update-Drivers updates drivers.
    .PARAMETER restart
        switch: Restarts the computer after updating.
    .PARAMETER force
        switch: Forces the update.
    .EXAMPLE
        Update-Drivers
    .OUTPUTS
        System.null
    #>

    $isAdmin = isadmin

    if ($force -and !($isAdmin)) {
        Admin "Update-Drivers"
        return
    }

    if (!($isAdmin)) {
        Write-Host('Please run this command as admin!') -Fore Red
        return
    }

    $UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager
    $UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher() 

    $Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
    $Searcher.SearchScope = 1 # MachineOnly
    $Searcher.ServerSelection = 3 # Third Party
          
    $Criteria = "IsInstalled=0 and Type='Driver'"
    Write-Host('Searching Driver-Updates...') -Fore Green     
    $SearchResult = $Searcher.Search($Criteria)          
    $Updates = $SearchResult.Updates
    if ([string]::IsNullOrEmpty($Updates)) {
        Write-Host "No pending driver updates."
    }
    else {
        #Show available Drivers...
        $Updates | Select-Object Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer | Format-List
        $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
        $updates | ForEach-Object { $UpdatesToDownload.Add($_) | out-null }
        Write-Host('Downloading Drivers...')  -Fore Green
        $UpdateSession = New-Object -Com Microsoft.Update.Session
        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToDownload
        $Downloader.Download()
        $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
        $updates | ForEach-Object { if ($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }

        Write-Host('Installing Drivers...')  -Fore Green
        $Installer = $UpdateSession.CreateUpdateInstaller()
        $Installer.Updates = $UpdatesToInstall
        $InstallationResult = $Installer.Install()
        if ($InstallationResult.RebootRequired) { 
            Write-Host('Reboot required! Please reboot now.') -Fore Red
            if ($restart -or $force) {
                Restart-Computer
            }
        }
        else { Write-Host('Done.') -Fore Green }
        $updateSvc.Services | Where-Object { $_.IsDefaultAUService -eq $false -and $_.ServiceID -eq "7971f918-a847-4430-9279-4a52d1efe18d" } | ForEach-Object { $UpdateSvc.RemoveService($_.ServiceID) }
    }
}



function Update-Windows([switch] $restart, [switch] $force) {
    <#
    .SYNOPSIS
        Updates Windows.
    .DESCRIPTION
        Updates Windows. For example, Update-Windows updates Windows.
    .PARAMETER restart
        switch: Restarts the computer after updating.
    .PARAMETER force
        switch: Forces the update.
    .EXAMPLE
        Update-Windows
    .OUTPUTS
        System.null
    #>      
    
    # Parameter help description

    $isAdmin = isadmin
    if ($force -and !($isAdmin)) {
        Admin "Update-Windows"
        return
    }
    if (!($isAdmin)) {
        Write-Host('Please run this command as admin! (or use the -Force switch)') -Fore Red
        return
    }
    Write-Host('Searching Windows-Updates...') -Fore Green
    Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
    Import-Module PSWindowsUpdate
    if ($restart -or $force) {
        Get-WindowsUpdate -Install -AcceptAll -AutoReboot | Out-Null
    } 
    else {
        Get-WindowsUpdate -Install -AcceptAll | Out-Null
    }
}

function Update-All {
    <#
    .SYNOPSIS
        Updates apps, Windows and drivers.
    .DESCRIPTION
        Updates apps, Windows and drivers. For example, Update-All updates Windows and drivers.
    .EXAMPLE
        Update-All
    .OUTPUTS
        System.null
    #>

    winget.exe upgrade --all
    Update-Drivers
    Update-Windows
}


function Install-Winget {
    <#
    .SYNOPSIS
        Updates/installs winget.
    .DESCRIPTION
        Updates/installs winget.
    .EXAMPLE
        Update-Winget
    .OUTPUTS
        System.null
    #>

    Write-Host "Installing winget..." -ForegroundColor Green
    $latestVersion = (Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest').tag_name
    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/$latestVersion/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$env:temp\WinGet.msixbundle"
    try {
        Add-AppxPackage "$env:temp\WinGet.msixbundle" -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to install winget" -ForegroundColor Red
        Install-MSXML
        Write-Host "trying to install winget again..." -ForegroundColor Green
        Add-AppxPackage "$env:temp\WinGet.msixbundle"
    }
    Write-Host "Finished" -ForegroundColor Green
}

function Install-MSXML {
    <#
    .SYNOPSIS
        Installs Microsoft UI XAML.
    .DESCRIPTION
        Installs Microsoft UI XAML. For example, Install-MSXML installs Microsoft UI XAML.
    .EXAMPLE
        Install-MSXML
    .OUTPUTS
        System.null
    #>

    Write-Host "Trying to install Microsoft.UI.Xaml package..." -ForegroundColor Yellow
    $zipPath = "$env:temp\microsoft.ui.xaml.zip"
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml" -OutFile $zipPath
    Expand-Archive $zipPath -DestinationPath $zipPath.TrimEnd(".zip") -Force
    Add-AppxPackage $(Get-ChildItem -Path "$($zipPath.TrimEnd(".zip"))\tools\AppX\x64\Release\" -Filter "*.appx")[0].FullName -ErrorAction Stop
    Remove-Item -Path $zipPath.TrimEnd(".zip") -Recurse -Force
    Remove-Item -Path $zipPath -Force
    Write-Host "Microsoft.UI.Xaml package install finished" -ForegroundColor Green
}