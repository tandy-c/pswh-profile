<#
 # time.ps1
 # holds time related functions and commands
 #>
function UnixTimeStamp {
    <#
    .SYNOPSIS
        Returns the current unix timestamp.
    .DESCRIPTION
        Returns the current unix timestamp. For example, Unix-Timestamp is the current unix timestamp.
    .EXAMPLE
        Unix-Timestamp
    .OUTPUTS
        System.String
    #>
    return [int64](Get-Date -UFormat %s -Millisecond 0)
}