{
  flake.nixosModules.lxc-configuration = {
    proxmoxLXC.manageHostName = true;
    proxmoxLXC.manageNetwork = true;
    systemd.services.console-getty.enable = false;
  };
}
