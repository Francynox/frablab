{ inputs, ... }:
{
  flake.nixosModules.lxc =
    { config, lib, ... }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
      ];

      proxmoxLXC.manageHostName = true;
      proxmoxLXC.manageNetwork = true;
      systemd.services.console-getty.enable = false;

      services.francynox.auto-update.mode = lib.mkDefault "push";
      services.francynox.lxc-wipe-on-boot.enable = config.frablab.base.persistence.enable;
    };
}
