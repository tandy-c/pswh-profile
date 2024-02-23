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
    $sqlite = Get-First-Path-If-Exists "$env:Programfiles\WinGet\Links\sqlite3.exe" "$env:Programfiles (x86)\WinGet\Links\sqlite3.exe"
    if (!($sqlite)) {
        Write-Output "Sqlite not found." -Fore Red
        return
    }
    Start-Process $sqlite -ArgumentList "-init $(Join-Path (Split-Path -Parent $profile.CurrentUserAllHosts) '.sqliterc')", "$args"
}

