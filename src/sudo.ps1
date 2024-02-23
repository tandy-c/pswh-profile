<#
 # sudo.ps1
 # holds a recreation of the sudo command
 # Admin: elevates powershell or command to admin
 #>


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
    $isAdmin = isadmin
    if ($args.Count -gt 0) {
        if ((Get-Command $args[0]).Definition.EndsWith(".exe")) {
            return Start-Process (Get-Command $args[0]).Definition -Verb RunAs -ArgumentList ($args[1..($args.Length - 1)] -join " ") -WorkingDirectory $PWD
        }
        if ($isAdmin) {
            return & $args
        }
        return Start-Process $pwrsh -Verb RunAs -WorkingDirectory $PWD -ArgumentList "-NoExit", "-NoLogo", "-Command & {$args}"
    }
    if ($isAdmin) {
        return Write-Host("Shell is already running as admin.") -Fore Red
    }
    Start-Process $pwrsh -Verb runAs -ArgumentList "-NoExit", "-NoLogo"
}