<#
 # profile_utils.ps1
 # holds profile related functions and commands
 # Edit-Profile: Opens the profile in the default editor.
 # Reload: Reloads the profile.
 # Update-Profile: Updates the profile.
 # User: Returns the current user.
 #>
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
    try {
        code (get-item $profile.CurrentUserAllHosts).Directory
    }
    catch {
        Invoke-Item $profile.CurrentUserAllHosts
    } 

}


function Restart-Profile {
    <#
    .SYNOPSIS
        Reloads the profile.
    .DESCRIPTION
        Reloads the profile. For example, reload reloads the profile.
    .EXAMPLE
        reload
    .OUTPUTS
        System.null
    #>
    . $profile.CurrentUserAllHosts
}

function Update-Profile {
    <#
    .SYNOPSIS
        Updates the profile.
    .DESCRIPTION
        Updates the profile. For example, Update-Profile updates the profile.
    .EXAMPLE
        Update-Profile
    .OUTPUTS
        System.null
    #>
    $currentLocation = $PWD
    Set-Location (Get-Item $profile.CurrentUserAllHosts).Directory
    git pull
    Set-Location $currentLocation
}

function User {
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

    if (isadmin) {
        return "$([char]27)[1;31m$env:USERNAME$([char]27)[0m"
    }
    return $env:USERNAME
}
