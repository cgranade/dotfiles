# Ensure that Get-ChildItemColor is loaded
Import-Module Get-ChildItemColor

# Set l and ls alias to use the new Get-ChildItemColor cmdlets
Set-Alias l Get-ChildItemColor -Option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

Import-Module posh-git
Start-SshAgent -Quiet

Add-PSSnapIn Microsoft.HPC

function Remove-Bom() {
    # See https://stackoverflow.com/a/5596984.
    param([string] $Path);
    $resolved = Resolve-Path $Path;
    $contents = Get-Content $resolved;
    $encoding = New-Object System.Text.UTF8Encoding $False;
    [System.IO.File]::WriteAllLines($resolved, $contents, $encoding);
}

Import-Module -Name oh-my-posh
Set-Theme Agnoster

if ($Env:TERM_PROGRAM -eq "vscode") {
    # Fix for the missing "DarkYellow" color in VS Code.
    $ThemeSettings.Colors["GitLocalChangesColor"] = "White"
}

$oldPrompt = $Function:prompt;

function prompt() {
    & $oldPrompt;

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
