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

    try {
        $isAdmin = isadmin -ErrorAction Stop
    }
    catch {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($force -and !($isAdmin)) {
        Admin "Update-Drivers"
        return
    }
    if (!($isAdmin)) {
        Write-Host('Please run this command as admin!') -Fore Red
        return
    }
    

    # you think i know what any of this shit does? lol

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
        return
    }
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

    try {
        $isAdmin = isadmin -ErrorAction Stop
    }
    catch {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
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
