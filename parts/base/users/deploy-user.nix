{
  flake.nixosModules.base-users-deploy-user =
    { lib, ... }:
    {
      services.francynox.deploy-user = {
        enable = lib.mkDefault true;
        sshAuthorizedKeys = lib.mkDefault [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRYcXzrg9ZDA3SumfawI7CDG43P9O5acMQiQiXG7EO1 deploy@frablab"
        ];
      };
    };
}
