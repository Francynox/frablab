{ self, config, ... }:
{
  imports = [ self.nixosModules.base ];

  frablab.base = {
    enable = true;
    auto-update.enable = false;
    networking.enable = false;
    persistence.enable = false;
    swap.enable = false;
  };
  frablab.user.autologin = true;

  nix.settings.accept-flake-config = true;
  programs.bash.shellAliases = {
    install = "nix run github:Francynox/frablab#install -- --experimental-features 'nix-command flakes'";
  };
}
