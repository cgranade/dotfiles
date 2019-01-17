# For the most part, we just source the PoSh Core profile.
. ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1

# We can now add Windows PowerShell–specific stuff.
Add-PSSnapIn Microsoft.HPC

#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
(& C:\Users\chgranad.REDMOND\Source\Repos\conda\devenv\Scripts\conda.exe shell.powershell hook) | Out-String | Invoke-Expression
#endregion

