{
  domain = "home.arpa";
  dhcpDomain = "dhcp.home.arpa";
  ns = "mimir.service.home.arpa.";
  adminEmail = "admin@home.arpa";

  subnets = {
    main = {
      id = 1;
      prefix = "10.0.10";
    };
    iot = {
      id = 2;
      prefix = "10.0.20";
    };
    guest = {
      id = 3;
      prefix = "10.0.30";
      validLifetime = 3600;
    };
    dmz = {
      id = 4;
      prefix = "10.0.70";
    };
    mgmt = {
      id = 6;
      prefix = "10.0.90";

      hosts = {
        nixos-dev = "10";
        zyxel-studio = "2";
        zyxel-sala = "3";
        mikrotik-switch = "4";
        proxmox = "5";
      };
    };

    service = {
      id = 5;
      prefix = "10.0.80";

      hosts = {
        bifrost = "250";
        mimir = "249";
        sparkyfitness = "240";
      };
    };
  };
}
