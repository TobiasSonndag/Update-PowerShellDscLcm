# Update-PowerShellDscLcm
PowerShell Script to configure a node for PowerShell DSC SMB Pull Server. It sets the node to pull node and configuration ID to the computer objects Active Directory GUID.

# Get started
Either use it manually on the node with PowerShell 7:
```powershell
.\Update-PowerShellDscLcm.ps1
```
or create an application in SCCM \
Installation program:
```powershell
pwsh.exe "Set-PowerShellDscLcm.ps1"
```
For detection use custom script and select Detect.ps1.

