#!/usr/bin/env pwsh

# Install dependencies.
$Dependencies = @(
    "PSGitDotfiles", "posh-git", "Get-ChildItemColor", "oh-my-posh"
);
Install-Module -Name $Dependencies -Force

# Find where this repo is.
Push-Location $PSScriptRoot;
    $RepoPath = git rev-parse --show-toplevel;
Pop-Location;

# Point PSGitDotfiles at whereever this repo is located.
Install-GitDotfiles -Uri $RepoPath;

# Note tht this means that the remote used by the dot alias points at the local
# bootstrap folder, and not to the upstream repo. Thus, we set the remote
# manually.
Invoke-GitDotfiles remote set-url origin https://github.com/cgranade/dotfiles.git
Invoke-GitDotfiles remote add bootstrap $RepoPath

# If the .NET Core SDK is available, but not dotnet-suggest,
# go on and add suggestion support.
if ((Get-Command dotnet -ErrorAction SilentlyContinue) -and -not (Get-Command dotnet-suggest -ErrorAction SilentlyContinue)) {
    dotnet tool install --global dotnet-suggest
}
