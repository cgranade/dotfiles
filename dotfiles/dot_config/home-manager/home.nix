# It is very wrong and cursed to have chezmoi manage this file,
# but I promise there's good reasons for it (see README.md).
# Good reasons aside, config should likely start here, then use direct
# dotfiles as a backup only.
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cgranade";
  home.homeDirectory = "/home/cgranade";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.nerdfonts
    pkgs.librewolf
    pkgs.openscad
    pkgs.gh
    pkgs.typst
    pkgs.tor-browser

    # Used for managing ssh agents in i3.
    # See https://superuser.com/a/1596398.
    pkgs.keychain
    # prusa-slicer fails when built from nix for some reason, so we
    # skip it here.

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cgranade/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # We need to set XDG paths here and not in sessionVariables
  # so that we can refer to their previous values.
  # See https://unix.stackexchange.com/questions/310666/nix-desktop-files
  # for why this works.
  programs.bash = {
    enable = true;
    profileExtra = ''
      # Enable cargo.
      . "$HOME/.cargo/env"
      # Set .desktop shortcuts.
      export XDG_DATA_DIRS=$HOME/.nix-profile/share:$HOME/.share:"''${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"

      # Enable keychain (see home.nix for why)
      eval $(keychain --eval --agents ssh --quick --quiet)
    '';
    bashrcExtra = ''      
      # Set up bash settings managed by chezmoi.
      # Those settings should be moved to be
      # directly in this file as soon as possible.
      . "$HOME/.bash_aliases"
    '';
  };

  programs.carapace.enable = true;
  programs.carapace.enableBashIntegration = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableBashIntegration = true;
  programs.starship.enable = true;
  programs.starship.enableBashIntegration = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
