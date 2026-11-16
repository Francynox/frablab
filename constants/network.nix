{
  domain = "home.arpa";
  dhcpDomain = "dhcp.home.arpa";
  ns = "mimir.service.home.arpa.";
  adminEmail = "admin@home.arpa";
  dns = [ "10.0.80.250" ];

  subnets = {
    main = {
      id = 1;
      cidr = "10.0.10.0/24";
      gateway = "10.0.10.254";
      dhcp = {
        start = "10.0.10.100";
        end = "10.0.10.200";
      };

      hosts = {
        gateway-master = "10.0.10.252";
        gateway-slave = "10.0.10.253";
      };
    };

    iot = {
      id = 2;
      cidr = "10.0.20.0/24";
      gateway = "10.0.20.254";
      dhcp = {
        start = "10.0.20.100";
        end = "10.0.20.200";
      };

      hosts = {
        gateway-master = "10.0.20.252";
        gateway-slave = "10.0.20.253";
      };
    };

    guest = {
      id = 3;
      cidr = "10.0.30.0/24";
      gateway = "10.0.30.254";
      dhcp = {
        start = "10.0.30.100";
        end = "10.0.30.200";
        validLifetime = 3600;
      };

      hosts = {
        gateway-master = "10.0.30.252";
        gateway-slave = "10.0.30.253";
      };
    };

    dmz = {
      id = 4;
      cidr = "10.0.70.0/24";
      gateway = "10.0.70.254";
      dhcp = {
        start = "10.0.70.100";
        end = "10.0.70.200";
      };

      hosts = {
        gateway-master = "10.0.70.252";
        gateway-slave = "10.0.70.253";
      };
    };

    service = {
      id = 5;
      cidr = "10.0.80.0/24";
      gateway = "10.0.80.254";
      dhcp = {
        start = "10.0.80.100";
        end = "10.0.80.200";
      };

      hosts = {
        gateway-master = "10.0.80.252";
        gateway-slave = "10.0.80.253";
        bifrost = "10.0.80.250";
        mimir = "10.0.80.249";
        sparkyfitness = "10.0.80.240";
      };
    };

    mgmt = {
      id = 6;
      cidr = "10.0.90.0/24";
      gateway = "10.0.90.254";
      dhcp = {
        start = "10.0.90.100";
        end = "10.0.90.200";
      };

      hosts = {
        gateway-master = "10.0.90.252";
        gateway-slave = "10.0.90.253";
        nixos-dev = "10.0.90.10";
        zyxel-studio = "10.0.90.2";
        zyxel-sala = "10.0.90.3";
        mikrotik-switch = "10.0.90.4";
        proxmox = "10.0.90.5";
      };
    };

    pppoe = {
      id = 7;
      cidr = "10.0.100.248/29";
      gateway = {
        ipv4 = "10.0.100.249";
        name = "pppoe";
      };

      hosts = {
        gateway-master = "10.0.100.252";
        gateway-slave = "10.0.100.253";
      };
    };
  };
}
