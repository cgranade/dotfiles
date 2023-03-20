## MODULE IMPORTS ############################################################

Import-Module posh-git
Import-Module posh-cargo
Import-Module posh-dotnet
Import-Module DockerCompletion

## SUGGESTION ENGINES ########################################################

# If rustup is installed, use its completions as well.
if ((Get-Command rustup -ErrorAction SilentlyContinue).Count -gt 0) {
    rustup completions powershell | Out-String | Invoke-Expression
}

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})

## COMMANDS ##################################################################

# Get-Command is very powerful, but
# we often want something quick, as the less powerful
# native command `which` gives us.
function which {
    param(
        [string] $name
    )

    $cmd = Get-Command $name -ErrorAction Ignore
    if (-not $cmd) {
        return
    } else {
        switch ($cmd.CommandType) {
            "Alias" {
                return "{0} -> {1}" -f $cmd.Name, $cmd.Definition
            }

            "Application" {
                return $cmd.Path
            }

            "Function" {
                return "function {0}" -f $cmd.Name
            }

            default {
                return $cmd
            }

        }
    }
}

## *IX-SPECIFIC ##############################################################

if ($IsLinux -or $IsMacOS) {

    # Configure aliases to point to built-in cmdlets over native commands.
    # We use -ErrorAction Ignore to deal with the case where these
    # aliases may already be defined.
    New-Alias -Name "cp" -Value Copy-Item -ErrorAction Ignore
    New-Alias -Name "ls" -Value Get-ChildItem -ErrorAction Ignore
    New-Alias -Name "mv" -Value Move-Item -ErrorAction Ignore
    New-Alias -Name "rm" -Value Remove-Item -ErrorAction Ignore
    New-Alias -Name "rmdir" -Value Remove-Item -ErrorAction Ignore

}

## WINDOWS-SPECIFIC ##########################################################

if ($IsWindows) {
    # Chocolatey profile
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path ($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}

## CONDA #####################################################################

# If there exists a conda profile, add it now.
# This is a nonstandard way of using conda init, but it lets us more easily
# include conda support in the dotfiles repo.
if (Test-Path ~/.conda-profile.ps1) {
    . ~/.conda-profile.ps1;
}

## PROMPT ####################################################################
# We customize the prompt last to prevent conda from clobbering it.

# Save the prompt function out so that we can disable it using $UseFancyPrompt.
if ((Get-Command -ErrorAction SilentlyContinue starship)) {
    Write-Host "Using starship.rs...";
    Invoke-Expression (&starship init powershell)
    $oldPrompt = $Function:Prompt;
    $Global:UseFancyPrompt = $true;
} else {
    $Global:UseFancyPrompt = $false;
}

function prompt {
    if ($Global:UseFancyPrompt) {
        & $oldPrompt;
    } else {
        # Fall back to a simple prompt for use in demos and presentations.
        $dirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList (Get-Location);
        $baseDir = $dirInfo.Name;
        Write-Host -NoNewline "PS $baseDir>  "

        "`b"
    }

}
