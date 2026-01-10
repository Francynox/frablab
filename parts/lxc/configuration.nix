{
  flake.nixosModules.lxc-configuration = {
    proxmoxLXC.manageHostName = true;
    proxmoxLXC.manageNetwork = true;
  };
}
