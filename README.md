# johan's custom powershell profile

custom powershell profile with some useful functions and aliases for my personal use. on github for easy access and sharing across work and school computers.

adopted from [Tim Sneath](tim@sneath.org) <https://gist.github.com/timsneath/19867b12eee7fd5af2ba>

![screenshot](https://lh3.googleusercontent.com/u/0/drive-viewer/AEYmBYSVLfLeu2NBa9nwZzdc21vmuySMcID2WOv55jEcEQ0nAR1J6Ya72Act4mLHxpcZXrpjAzYb4sQtX3AtihB9o8yl0BkWDQ=w1920-h973)

you may want to add -NoLogo to any instance of powershell.exe

## installation

create a powershell profile by entering this directly into powershell, and then you could just do what you want with this `profile.ps1` file:

1. open powershell and enter:

   ```PS1
   if (!(Test-Path $PROFILE.CurrentUserAllHosts)) {
       New-Item $PROFILE.CurrentUserAllHosts -ItemType File -Force 
   }
   ```

2. open the file with:

   ```PS1
   notepad $PROFILE.CurrentUserAllHosts
   ```

   OR:

    ```PS1
    Invoke-Item $PROFILE.CurrentUserAllHosts
    ```

## commands

- `Edit-Profile` - opens the profile file (you may need to make `.ps1` files open with your preferred text editor by default)
- `Admin` or `sudo` - runs the following command as administrator, or opens a new powershell window as administrator if no command is given
- `Get-IP` - gets the public IP address of the current machine
- `whereis` - finds the location of a file on path
- `Update-Drivers`, `Update-Windows`, `Update-All` - updates drivers, windows, or both + winget apps
