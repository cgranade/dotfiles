# dotfiles

This dotfiles repo uses [chezmoi](https://www.chezmoi.io/) to manage dotfiles across operating systems.

## Setup

```
$ chezmoi init https://github.com/cgranade/dotfiles.git
$ chezmoi diff # Check that it looks right first!
$ chezmoi apply
```

## Assumed dependencies

- chezmoi itself
- nushell
- starship
- git
- pwsh
- zoxide
- cargo

## This is very cursed‽

Currently, this repo uses chezmoi to manage nix's home-manager. This is exactly backwards, but I do it for three reasons:

- chezmoi supports windows
- I was already using chezmoi, and this allows for gradually moving stuff over to home-manager as I have time/energy/spoons.
- home-manager doesn't have options for some stuff I need (e.g.: I do work with pwsh sometimes), which reduces the benefit compared with managing dotfiles directly.

Eventually, this should be fully inverted, with chezmoi being a thin shim over home-manager that I can then completely remove.
