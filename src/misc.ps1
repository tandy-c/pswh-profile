<#
 # misc.ps1
 # holds misc functions that interract with .exe files
 #>

function Open-Sqlite {
    <#
    .SYNOPSIS
        Initializes sqlite.
    .DESCRIPTION
        Initializes sqlite. For example, Init-Sqlite initializes sqlite.
    .EXAMPLE
        Init-Sqlite
    .OUTPUTS
        System.null
    #>
    $sqlite = Get-First-Path-If-Exists "$env:Programfiles\WinGet\Links\sqlite3.exe" "$env:Programfiles (x86)\WinGet\Links\sqlite3.exe" "$env:localappdata\Microsoft\WinGet\Packages\SQLite.SQLite_Microsoft.Winget.Source_8wekyb3d8bbwe"
    if (!($sqlite)) {
        Write-Output "Sqlite not found." -Fore Red
        return
    }
    Start-Process $sqlite -ArgumentList "-init $(Join-Path (Split-Path -Parent $profile.CurrentUserAllHosts) '.sqliterc')", "$args"
}

function Eject {
    <#
    .SYNOPSIS
        Ejects a drive.
    .PARAMETER driveLetter
        string: The drive letter to eject.
    .PARAMETER namespace
        int: The namespace to use.
    .EXAMPLE
        Eject "D:"
    .OUTPUTS
        System.null
    #>
    # Parameter help description
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$driveLetter,
        [Parameter(Mandatory = $false)]
        [int]$namespace = 17
    )
    $driveEject = New-Object -comObject Shell.Application
    try {
        $driveEject.Namespace($namespace).ParseName($driveLetter).InvokeVerb("Eject")
    }
    catch [System.Management.Automation.RuntimeException] {
        Write-Host "Error: $_ Is the Drive in?" -ForegroundColor Red
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}