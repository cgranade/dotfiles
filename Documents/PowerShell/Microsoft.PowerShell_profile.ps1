## MODULE IMPORTS ############################################################

Import-Module PSGitDotfiles

Import-Module posh-git

Import-Module Get-ChildItemColor
    # Set l and ls alias to use the new Get-ChildItemColor cmdlets
    Set-Alias l Get-ChildItemColor -Option AllScope
    Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

Import-Module -Name oh-my-posh
    Set-Theme Agnoster


if ($Env:TERM_PROGRAM -eq "vscode") {
    # Fix for the missing "DarkYellow" color in VS Code.
    $ThemeSettings.Colors["GitLocalChangesColor"] = "White"
}

## PROMPT ####################################################################

$Global:UseFancyPrompt = $true;

$oldPrompt = $Function:prompt;

function Set-TerminalWindowTitle() {
    # pass, we'll override in OS-specific sections below.
}

function prompt() {

    if ($Global:UseFancyPrompt) {
        Set-TerminalWindowTitle | Out-Null;
        & $oldPrompt;
    } else {
        $dirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList (Get-Location);
        $baseDir = $dirInfo.Name;
        Write-Host -NoNewline "PS $baseDir>  "

        "`b"
    }

}

## COMMANDS ##################################################################

function Remove-Bom() {
    # See https://stackoverflow.com/a/5596984.
    param([string] $Path);
    $resolved = Resolve-Path $Path;
    $contents = Get-Content $resolved;
    $encoding = New-Object System.Text.UTF8Encoding $False;
    [System.IO.File]::WriteAllLines($resolved, $contents, $encoding);
}


# which is a bit more complicated...
# In particular, Get-Command is very powerful, but
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
    # Check if we're running in ConEmu.
    if ($null -ne $Env:ConEmuPID) {
        $IsConEmu = $true;
        Remove-Item function:/Set-TerminalWindowTitle

        function Set-TerminalWindowTitle() {
            if (Get-Command ConEmuC -ErrorAction SilentlyContinue) {
                $gitDir = Get-GitDirectory
                if ($gitDir) {
                    $gitRoot = Resolve-Path (Join-Path $gitDir ..)
                    $tabTitle = "Repo: $(Split-Path -Leaf $gitRoot)"
                } else {
                    $tabTitle = Split-Path -Leaf (Get-Location)
                }

                ConEmuC -GuiMacro Rename 0 "$tabTitle" > $null 2> $null

            }
        }   
    } else {
        $IsConEmu = $false;
    }



    # Chocolatey profile
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }

}

## CONDA CONFIG ##############################################################
# Since this is machine specific, we store our conda config in a
# ~/.conda.ps1 file rather than the default.
$CondaPath = (Resolve-Path ~/.conda.ps1);
if (Test-Path $CondaPath) {
    . $CondaPath;
}
