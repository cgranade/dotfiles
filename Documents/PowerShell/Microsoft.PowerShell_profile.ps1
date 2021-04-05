## MODULE IMPORTS ############################################################

Import-Module PSGitDotfiles

Import-Module posh-git


function Set-TerminalWindowTitle() {
    # pass, we'll override in OS-specific sections below.
}



## SUGGESTION ENGINES ########################################################

# dotnet suggest shell start
$availableToComplete = (dotnet-suggest list) | Out-String
$availableToCompleteArray = $availableToComplete.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)


    Register-ArgumentCompleter -Native -CommandName $availableToCompleteArray -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        $fullpath = (Get-Command $wordToComplete.CommandElements[0]).Source

        $arguments = $wordToComplete.Extent.ToString().Replace('"', '\"')
        dotnet-suggest get -e $fullpath --position $cursorPosition -- "$arguments" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
$env:DOTNET_SUGGEST_SCRIPT_VERSION = "1.0.0"
# dotnet suggest script end

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

# If https://github.com/Matt-Gleich/fgh is installed, use that to define
# some new aliases for jumping around to different repos.
# TODO: provide tab completion using technique at https://github.com/conda/conda/blob/master/conda/shell/condabin/Conda.psm1#L188.
if ((Get-Command -ErrorAction SilentlyContinue fgh)) {
    function Set-LocationToRepo() {
        param(
            [string]
            $RepoName
        )

        $path = fgh ls $RepoName;
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to find $RepoName."; 
        } else {
            Set-Location -Path $path;
        }
    }

    function Push-LocationToRepo() {
        param(
            [string]
            $RepoName
        )

        $path = fgh ls $RepoName;
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to find $RepoName."; 
        } else {
            Push-Location -Path $path;
        }
    }

    function Invoke-CodeOnRepo() {
        param(
            [string]
            $RepoName
        )

        $path = fgh ls $RepoName;
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to find $RepoName."; 
        } else {
            code $path;
        }
    }

    New-Alias -Name "fcd" -Value Set-LocationToRepo;
    New-Alias -Name "pushr" -Value Push-LocationToRepo;
    New-Alias -Name "icr" -Value Invoke-CodeOnRepo;
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

# If there exists a conda profile, add it now.
# This is a nonstandard way of using conda init, but it lets us more easily
# include conda support in the dotfiles repo.
if (Test-Path ~/.conda-profile.ps1) {
    . ~/.conda-profile.ps1;
}

## PROMPT ####################################################################
# We customize the prompt last to prevent conda from clobbering it.

# If starship.rs is available use it instead of oh-my-posh to get cross-shell
# support.

# Whichever prompt engine we use, though, save its prompt function out so that
# we can disable it using $UseFancyPrompt.
if ((Get-Command -ErrorAction SilentlyContinue starship)) {
    Write-Host "Using starship.rs...";
    $ENV:STARSHIP_CONFIG = Join-Path (Resolve-Path "~") ".starship";

    $starshipInit = @(starship init powershell --print-full-init) -join "`n";
    Invoke-Expression ($starshipInit -replace "global:prompt", "starshipPrompt");
    $oldPrompt = $Function:starshipPrompt;
} else {
    Write-Host "Using oh-my-posh...";
    
    Import-Module -Name oh-my-posh;
    Set-Theme Agnoster;

    $oldPrompt = $Function:prompt;
    
    if ($Env:TERM_PROGRAM -eq "vscode") {
        # Fix for the missing "DarkYellow" color in VS Code.
        $ThemeSettings.Colors["GitLocalChangesColor"] = "White"
    } else {
        # VS Code's integrated terminal does not like the ⚙️ emoji.
        $global:ThemeSettings.PromptSymbols.VirtualEnvSymbol = "⚙️";
    }

}

$Global:UseFancyPrompt = $true;

function prompt {
    if ($Global:UseFancyPrompt) {
        Set-TerminalWindowTitle | Out-Null;
        & $oldPrompt;
    } else {
        # Fall back to a simple prompt for use in demos and presentations.
        $dirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList (Get-Location);
        $baseDir = $dirInfo.Name;
        Write-Host -NoNewline "PS $baseDir>  "

        "`b"
    }

}
