<# 
    This file should be stored in $PROFILE.CurrentUserAllHosts
    if (!Test-Path $PROFILE.CurrentUserAllHosts) { New-Item $PROFILE.CurrentUserAllHosts -ItemType File -Force }
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#>
Import-module "$(Split-Path -Parent $profile.CurrentUserAllHosts)\src\__src__.ps1" -Force

function _Main {
    <#
    .SYNOPSIS
        Main initializer function for the profile.
    .DESCRIPTION
        Main initializer function for the profile; sets aliases, etc.
    #>

    # Set up the window title to show the PowerShell version and whether it's elevated
    $Host.UI.RawUI.WindowTitle = "PowerShell $($psVersion)"
    $isAdmin = isadmin

    if ($isAdmin) {
        $Host.UI.RawUI.WindowTitle += " - Admin"
    }
    $aliasHash = @{
        #unix
        "top"             = "Get-Current-Process";
        "touch"           = "New-Item";
        "which"           = "Get-CommandPath";
        "grep"            = "Select-String";
        "getpid"          = "{Get-Process -Id $PID}";
        "htop"            = "{Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 20}"
        "unzip"           = "Expand-Archive";
        "zip"             = "Compress-Archive";
        "apt"             = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe";
        "reboot"          = "Restart-Computer";
        # "curl"            = "Invoke-WebRequest";
        "wait"            = "Start-Sleep";
        #windows
        "dirs"            = "Get-All-ChildItem";
        "n"               = "$env:windir\notepad.exe";
        "np"              = "$env:windir\notepad.exe";
        #me
        "python3"         = "$env:Programfiles\Python312\python.exe";
        "sqlite"          = "Open-Sqlite";
        "sqlite3"         = "Open-Sqlite";
        "open"            = "Invoke-Item";
        "run"             = "Invoke-Item";
        "exec"            = "Invoke-Item";
        "Upgrade-Drivers" = "Update-Drivers";
        "Upgrade-Windows" = "Update-Windows";
        "refresh"         = "Restart-Profile";
        "reload"          = "Restart-Profile";
        "sysinfo"         = "Get-ComputerInfo";
        "profile"         = "Edit-Profile";
        "cdmkdir"         = "New-Directory-Set-Location";
        "mkdircd"         = "New-Directory-Set-Location";
        "rename"          = "Rename-Item";
        "path"            = "Show-Path";
        "rn"              = "Rename-Item";
        "remove"          = "Remove-Item";
     
    }
    foreach ($kv in $aliasHash.GetEnumerator()) {
        # add a check here to say if .exe path or command is valid
        if ($kv.Value.EndsWith(".exe") -and !(Test-Path $kv.Value)) {
            continue
        }
        if ($kv.Value.StartsWith("{") -and $kv.Value.EndsWith("}")) {
            New-Item -Path "function:\" -Name "global:$($kv.Key)" -Value $($kv.Value.ToString().Trim("}", "{")) -Force  | Out-Null 
            continue
        }
        Set-Alias -Name $kv.Name -Value $kv.Value -Scope Global -Description "Alias for $($kv.Value)" -Force | Out-Null 
    }
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $cimInstance = Get-CimInstance -ClassName Win32_ComputerSystem
    if ((Get-Random -Maximum 100) -le 5) {
        $newestVersion = Get-LatestPowerShellVersion
        Update-Profile
        Clear-Host
        Write-Host "PowerShell $($psVersion)" -NoNewline
        if ($psVersion -ge ($newestVersion)) {
            Write-Host " > $((Get-Culture).TextInfo.ToTitleCase($cimInstance.Manufacturer.ToLower())) $($cimInstance.Model)" -ForegroundColor DarkGray
        }
        else {
            Write-Host " > PowerShell $newestVersion is available" -ForegroundColor Green
            Write-Host ""
            Write-Host "https://github.com/powershell/powershell/releases" -ForegroundColor DarkGray
            Write-Host "sudo winget upgrade --id Microsoft.Powershell" -ForegroundColor DarkGray
        }
    }
    else {
        Clear-Host
        Write-Host "PowerShell $($psVersion)" -NoNewline
        Write-Host " > $((Get-Culture).TextInfo.ToTitleCase($cimInstance.Manufacturer.ToLower())) $($cimInstance.Model)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host $(User) -NoNewline -ForegroundColor DarkGray
    Write-Host "@$(HOSTNAME.EXE)" -ForegroundColor DarkGray
    Write-Host "$((Get-Date -UFormat "%m/%d/%Y %I:%M:%S %p").ToLower())" -ForegroundColor DarkGray -NoNewline
}




function PostMain {
    <#
    .SYNOPSIS
        Runs after the main initializer function.
    .DESCRIPTION
        Runs after the main initializer function. For example, Post-Main runs after the main initializer function.
    .EXAMPLE
        Post-Main
    .OUTPUTS
        System.String
    #>
    # Set the default location to the user's home directory
    $executionTime = (Measure-Command { _Main }).TotalMilliseconds
    $message = " ($([Math]::Floor($executionTime)) ms)"
    
    if ($executionTime -gt 1000) {
        Write-Host $message -ForegroundColor Red
    }
    elseif ($executionTime -gt 500) {
        Write-Host $message -ForegroundColor DarkGray
    }
    else {
        Write-Host ""
    }
    Write-Host ""
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

    if (isadmin) {
        $ESC = [char]27
        return "$ESC[1;31mPS $ESC[0m$($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))"
    }
    return "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "  
}

PostMain
