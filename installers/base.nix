{ self, constants, ... }:
{
  imports = [ self.nixosModules.base ];

  frablab.base = {
    enable = true;
    auto-update.enable = false;
    users.deploy-user.autologin = true;
  };

  nix.settings.accept-flake-config = true;
  programs.bash.shellAliases = {
    install = "nix run ${constants.flakeUrl}#install -- --experimental-features 'nix-command flakes'";
  };
}
