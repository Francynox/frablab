{ self, config, ... }:
{
  imports = [ self.nixosModules.base ];

  frablab.base = {
    enable = true;
    auto-update.enable = false;
    swap.enable = false;
  };
  frablab.deploy-user.autologin = true;

  nix.settings.accept-flake-config = true;
  programs.bash.shellAliases = {
    install = "nix run github:Francynox/frablab#install -- --experimental-features 'nix-command flakes'";
  };
}
