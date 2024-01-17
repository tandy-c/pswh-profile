<# 
    This file should be stored in $PROFILE.CurrentUserAllHosts
    if (!Test-Path $PROFILE.CurrentUserAllHosts) { New-Item $PROFILE.CurrentUserAllHosts -ItemType File -Force }
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#>

# Find out if the current user identity is elevated (has admin rights)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


# Set up the window title to show the PowerShell version and whether it's elevated
$Host.UI.RawUI.WindowTitle = "PowerShell $($psVersion)"
if ($isAdmin) {
    $Host.UI.RawUI.WindowTitle += " - Admin"
}

function Get-LatestPowerShellVersion {
    <#
    .SYNOPSIS
        Returns the latest version of PowerShell.
    .DESCRIPTION
        Returns the latest version of PowerShell. For example, Get-LatestPowerShellVersion is the latest version of PowerShell.
    .EXAMPLE
        Get-LatestPowerShellVersion
    .OUTPUTS
        System.String
    #>

    # Get the latest release information from the GitHub API
    try {
        $defaultTimeout = [System.Net.ServicePointManager]::MaxServicePointIdleTime
        [System.Net.ServicePointManager]::MaxServicePointIdleTime = 10
        $response = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -MaximumRetryCount 0 -TimeoutSec 1
        [System.Net.ServicePointManager]::MaxServicePointIdleTime = $defaultTimeout
        return ($response.tag_name).TrimStart('v')
    }   
    catch {
        return $PSVersionTable.PSVersion.ToString()
    }
}

function prompt { 
    <#
    .SYNOPSIS
        Sets up the command prompt.
    .DESCRIPTION
        Sets up the command prompt. For example, prompt is the command prompt.
    .EXAMPLE
        prompt
    .OUTPUTS
        System.String
    #>
    if ($isAdmin) {
        $ESC = [char]27
        "$ESC[1;31mPS $ESC[0m$($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))"
    }
    else {
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "  
    }
}

function ?? {
    <#
    .SYNOPSIS
        Returns the last truthy value.
    .DESCRIPTION
        Returns the last truthy value. For example, ?? $a $b $c is the last truthy value.
    .EXAMPLE
        ?? $a $b $c
    .OUTPUTS
        Any
    #>

    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true, Position = 0)]
        [psobject[]]$InputObject,
  
        [switch]$Truthy
    )
  
    foreach ($object in $InputObject) {
        if ($Truthy -and $object) {
            return $object
        }
        elseif ($null -ne $object) {
            return $object
        }
    }
}

function Get-Ip([switch]$Copy) {
    <#
    .SYNOPSIS
        Returns the current IP address.
    .DESCRIPTION
        Returns the current IP address. For example, Get-Ip is the current IP address.
    .PARAMETER Copy
        switch: Copies the IP address to the clipboard.
    .EXAMPLE
        Get-Ip
    .OUTPUTS
        System.String
    #>
    $content = Invoke-WebRequest "ifconfig.me/ip" | Select-Object -ExpandProperty Content
    $ip = $content.Trim()
    if ($copy) {
        $ip | Set-Clipboard
        Write-Output "Copied to clipboard: "
    }
    return $ip
}

function Get-First-Path-If-Exists {
    <#
    .SYNOPSIS
        Returns the first path in the list that exists.
    .DESCRIPTION
        Returns the first path in the list that exists. For example, Get-First-Path-If-Exists "C:\Program Files\Git\bin" "C:\Program Files (x86)\Git\bin" is the first path that exists.
    .EXAMPLE
        Get-First-Path-If-Exists "C:\Program Files\Git\bin" "C:\Program Files (x86)\Git\bin"
    .OUTPUTS
        System.String
    #>
    foreach ($path in $args) {
        if (Test-Path $path) {
            return $path
        }
    }
}

function Get-All-ChildItem {
    <#
    .SYNOPSIS
        Does the the rough equivalent of dir /s /b. 
    .DESCRIPTION
        Does the the rough equivalent of dir /s /b. For example, Get-All-ChildItem *.png is dir /s /b *.png
    .EXAMPLE
        dirs *.png
    .OUTPUTS
        System.String
    #>
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    }
    else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Does the equivlent of top in Linux/Unix.
function Get-Current-Process([int] $Count = 15, [int] $Refresh = 1 ) {
    <#
    .SYNOPSIS
        Does the equivlent of top in Linux/Unix.
    .DESCRIPTION
        Does the equivlent of top in Linux/Unix. For example, Get-Current-Process 10 2 is top -n 10 -d 2
    .PARAMETER Count
        int: The number of processes to show.
    .PARAMETER Refresh
        int: The number of seconds to wait between refreshes.
    .EXAMPLE
        Get-Current-Process 10 2
    .OUTPUTS
        System.String
    #>

    While (1) { Get-Process | Sort-Object -des cpu | Select-Object -f $Count | Format-Table -a; Start-Sleep $Refresh; Clear-Host }
}

function Admin {
    <#
    .SYNOPSIS
        Elevates powershell or command to admin.
    .DESCRIPTION
        Elevates powershell or command to admin.
        Admin -> opens a new powershell window as admin.
        Admin <command -args> -> runs the command as admin.
    .EXAMPLE
        admin
    .OUTPUTS    
        System.String
    #>
    $pwrsh = Get-First-Path-If-Exists "$psHome\powershell.exe" "$psHome\pwsh.exe"
    if ($args.Count -gt 0) {
        if ((Get-Command $args[0]).Definition.EndsWith(".exe")) {
            Start-Process (Get-Command $args[0]).Definition -Verb RunAs -ArgumentList ($args[1..($args.Length - 1)] -join " ") -WorkingDirectory $PWD
        }
        else {
            Start-Process $pwrsh -Verb RunAs -WorkingDirectory $PWD -ArgumentList "-NoExit", "-NoLogo", "-Command & {$args}"
        }
    }
    else {
        Start-Process $pwrsh -Verb runAs -ArgumentList "-NoExit", "-NoLogo"
    }
    
}

function Get-CommandPath([string]$Command, [switch]$copy) {
    <#
    .SYNOPSIS
        Returns the path of a command.
    .DESCRIPTION
        Returns the path of a command. For example, Get-Path notepad is the path of notepad.
    .EXAMPLE
        Get-Path notepad
    .OUTPUTS
        System.String
    #>
    $path = (Get-Command $Command).Definition
    if ($copy) {
        $path | Set-Clipboard
        Write-Output "Copied to clipboard: "
    }
    return $path
}

function User([switch]$Copy) {
    <#
    .SYNOPSIS
        Returns the current user.
    .DESCRIPTION
        Returns the current user. For example, User is the current user.
    .EXAMPLE
        User
    .OUTPUTS
        System.String
    #>
    $user = $env:USERNAME
    if ($copy) {
        $user | Set-Clipboard
        Write-Output "Copied to clipboard: "
    }
    return $user
}



function Edit-Profile {
    <#
    .SYNOPSIS
        Opens the profile in the default editor.
    .DESCRIPTION
        Opens the profile in the default editor. Makes it easy to edit this profile once it's installed
    .EXAMPLE
        Edit-Profile
    .OUTPUTS
        System.String
    #>
    if ($host.Name -match "ise") {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else {
        Invoke-Item $profile.CurrentUserAllHosts
    }
}

function Update-Drivers {
    <#
    .SYNOPSIS
        Updates drivers.
    .DESCRIPTION
        Updates drivers. For example, Update-Drivers updates drivers.
    .EXAMPLE
        Update-Drivers
    .OUTPUTS
        System.null
    #>

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
        }
        else { Write-Host('Done.') -Fore Green }
        $updateSvc.Services | Where-Object { $_.IsDefaultAUService -eq $false -and $_.ServiceID -eq "7971f918-a847-4430-9279-4a52d1efe18d" } | ForEach-Object { $UpdateSvc.RemoveService($_.ServiceID) }
    }

}

function Update-Windows {
    <#
    .SYNOPSIS
        Updates Windows.
    .DESCRIPTION
        Updates Windows. For example, Update-Windows updates Windows.
    .EXAMPLE
        Update-Windows
    .OUTPUTS
        System.null
    #>      
    
    if (!($isAdmin)) {
        Write-Host('Please run this command as admin!') -Fore Red
        return
    }
    Write-Host('Searching Windows-Updates...') -Fore Green
    Install-Module PSWindowsUpdate -Force
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -Install -AcceptAll -AutoReboot | Out-Null
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

Function isadmin {
    <#
    .SYNOPSIS
        Returns whether the current user is admin.
    .DESCRIPTION
        Returns whether the current user is admin. For example, isadmin is whether the current user is admin.
    .EXAMPLE
        isadmin
    .OUTPUTS
        System.String
    #>
    $isAdmin
}


$aliasHash = @{
    "su"              = "Admin";
    "sudo"            = "Admin";
    "top"             = "Get-Current-Process";
    "touch"           = "New-Item";

    # "htop" = "Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 20";

    "md5"             = "Get-FileHash -Algorithm MD5";
    "sha1"            = "Get-FileHash -Algorithm SHA1";
    "sha256"          = "Get-FileHash -Algorithm SHA256";
    
    "HKLM:"           = "Set-Location HKLM:";
    "HKCU:"           = "Set-Location HKCU:";
    "Env:"            = "Set-Location Env:";

    "dirs"            = "Get-All-ChildItem";
    
    "n"               = "$env:windir\notepad.exe";
    "np"              = "$env:windir\notepad.exe";
    "python3"         = "$env:Programfiles\Python312\python.exe";
    "sqlite"          = "$env:Programfiles\WinGet\Links\sqlite3.exe";   
    "whereis"         = "Get-CommandPath";
    "open"            = "Invoke-Item";
    "Upgrade-Drivers" = "Update-Drivers";
    "Upgrade-Windows" = "Update-Windows";
    # "dir /s /b" = "Get-All-ChildItem";
}

foreach ($kv in $aliasHash.GetEnumerator()) {
    # add a check here to say if .exe path or command is valid
    if ("Set-Location HKCU:".EndsWith(".exe") -and !(Test-Path "Set-Location HKCU:")) {
        continue
    }
    Set-Alias -Name $kv.Name -Value $kv.Value -Scope Global -Description "Alias for $($kv.Value)"
}




$psVersion = $PSVersionTable.PSVersion.ToString()
$newestVersion = Get-LatestPowerShellVersion

Clear-Host
Write-Host "PowerShell $($psVersion)" -NoNewline
if ($psVersion -ge ($newestVersion)) {
    Write-Host " > https://github.com/tandy-c/pswh-profile" -ForegroundColor DarkGray
}
else {
    Write-Host " > PowerShell $newestVersion is available" -ForegroundColor Green
    Write-Host ""
    Write-Host "https://github.com/powershell/powershell/releases" -ForegroundColor DarkGray
    Write-Host "sudo winget upgrade --id Microsoft.Powershell" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "$(HOSTNAME.EXE) @ $($isAdmin ? "$([char]27)[1;31madmin " : '')$(User)$([char]27)[0m" -ForegroundColor DarkGray
Write-Host "$((Get-Date -UFormat "%m/%d/%Y %I:%M:%S %p").ToLower())" -ForegroundColor DarkGray
Write-Host ""