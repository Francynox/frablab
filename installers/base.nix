{ self, constants, ... }:
{
  imports = [ self.nixosModules.base ];

  services.francynox = {
    deploy-user.autologin = true;
  };

  nix.settings.accept-flake-config = true;
  programs.bash.shellAliases = {
    install = "nix --extra-experimental-features 'nix-command flakes' run ${constants.flakeUrl}#install";
  };
}
