{
  flake.nixosModules.base-users =
    { self, ... }:
    {
      imports = [
        self.nixosModules.base-users-admin
        self.nixosModules.base-users-deploy-user
      ];

      users.mutableUsers = false;
    };
}
