{
  flake.nixosModules.lxc-configuration =
    { config, ... }:
    {
      proxmoxLXC.manageHostName = true;
      proxmoxLXC.manageNetwork = true;
      systemd.services.console-getty.enable = false;

      frablab.base.auto-update.mode = "push";
      services.francynox.lxc-wipe-on-boot.enable = config.frablab.base.persistence.enable;
    };
}
