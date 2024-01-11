# johan's custom powershell profile

custom powershell profile with some useful functions and aliases for my personal use. on github for easy access and sharing across work and school computers.

![screenshot](https://lh3.googleusercontent.com/u/0/drive-viewer/AEYmBYSVLfLeu2NBa9nwZzdc21vmuySMcID2WOv55jEcEQ0nAR1J6Ya72Act4mLHxpcZXrpjAzYb4sQtX3AtihB9o8yl0BkWDQ=w1920-h973)

## installation

1. create a powershell profile by entering this directly into powershell:

    ```PS1
    if (!Test-Path $PROFILE.CurrentUserAllHosts) { New-Item $PROFILE.CurrentUserAllHosts -ItemType File -Force }
    ```

2. open the profile in notepad by entering this directly into powershell:

    ```PS1
    notepad $PROFILE.CurrentUserAllHosts
    ```

3. copy the contents of the profile.ps1 file in this repository into the profile you just opened in notepad; save and close notepad
