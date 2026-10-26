{
  flake.nixosModules.base-ssh = {
    services = {
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        openFirewall = true;
      };
    };
  };
}
