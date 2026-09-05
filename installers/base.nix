{ self, constants, ... }:
{
  imports = [ self.nixosModules.base ];

  frablab.base = {
    enable = true;
  };

  services.francynox = {
    auto-update.enable = false;
    deploy-user.autologin = true;
  };

  nix.settings.accept-flake-config = true;
  programs.bash.shellAliases = {
    install = "nix run ${constants.flakeUrl}#install -- --experimental-features 'nix-command flakes'";
  };
}
