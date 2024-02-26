<#
 # utils.ps1
 # holds general utility functions and commands
 # Write-HostCenter: Writes a message to the center of the console.
 # isadmin: Returns whether the current user is admin.
 # Get-LatestPowerShellVersion: Returns the latest version of PowerShell.
 # ??: Returns the last truthy value.
 # Get-Ip: Returns the current IP address.
 # Get-First-Path-If-Exists: Returns the first path in the list that exists.
 # Get-All-ChildItem: Does the the rough equivalent of dir /s /b.
 # Get-Current-Process: Does the equivlent of top in Linux/Unix.
 # Get-CommandPath: Returns the path of a command.
 # Largest: Returns the largest file in the current directory.
 # New-Directory-Set-Location: Creates a directory and sets the location to it.
 # Path: Displays path variables formatted
 #>

function Write-HostCenter { 
    param($Message) Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) 
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
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
        return Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    }
    return Get-ChildItem -Recurse | Foreach-Object FullName
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

function Get-CommandPath([string]$Command) {
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

    try {
        return (Get-Command $Command $args).Definition
    }
    catch {
        return (Get-Command $Command).Definition
    }

    
}





function Largest {
    <#
    .SYNOPSIS
        Returns the largest file in the current directory.
    .DESCRIPTION
        Returns the largest file in the current directory. For example, Largest is the largest file in the current directory.
    .EXAMPLE
        Largest
    .OUTPUTS
        System.String
    #>
    Get-ChildItem -re -in * |
    Where-Object { -not $_.PSIsContainer } |
    Sort-Object Length -descending |
    Select-Object -first 10

}

function New-Directory-Set-Location {
    <#
    .SYNOPSIS
        Creates a directory and sets the location to it.
    .DESCRIPTION
        Creates a directory and sets the location to it. For example, Create-Directory-Set-Location "C:\Users\Public\Documents" is mkdir "C:\Users\Public\Documents" && cd "C:\Users\Public\Documents"
    .EXAMPLE
        Create-Directory-Set-Location "C:\Users\Public\Documents"
    .OUTPUTS
        System.null
    #>
    $directory = $args[0]
    New-Item -ItemType Directory -Path $directory
    Set-Location $directory
    Write-Host ""
    Write-Host "Set location to $directory" -Fore Green
}


function Path {
    <#
    .SYNOPSIS
        Displays path variables formatted
    .DESCRIPTION
        Formats the output of $env:path to be more readable.
    #>

    $env:path -split ";" | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
}



function Set-DynamicAlias {

    <#
    .SYNOPSIS
        Sets a dynamic alias.
    .DESCRIPTION
        Sets a dynamic alias. For example, Set-DynamicAlias "g" "git" is g is git.
    .EXAMPLE
        Set-DynamicAlias s1 'Write-Host "sample 1"'
    .OUTPUTS
        System.null
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Alias,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Command
    )
    New-Item -Path function:\ -Name "global:$Alias" -Value "$Command `$args" -Force | Out-Null
}

function Source {
    <#
    .SYNOPSIS
        Sources a file.
    .DESCRIPTION
        Sources a file. For example, Source "C:\Users\Public\Documents\profile.ps1" is source "C:\Users\Public\Documents\profile.ps1"
    .EXAMPLE
        Source "C:\Users\Public\Documents\profile.ps1"
    .OUTPUTS
        System.null
    #>
    . $args
}