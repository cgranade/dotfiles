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
