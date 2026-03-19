{
  flake.nixosModules.vm-disko-main =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.frablab.vm.disko.main;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      options.frablab.vm.disko.main = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable disko for vm";
        };
        device = lib.mkOption {
          type = lib.types.str;
          default = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
          description = "The disk device to use";
        };
        rootSize = lib.mkOption {
          type = lib.types.str;
          default = "2G";
          description = "Size of the tmpfs mount";
        };
      };

      config = lib.mkIf cfg.enable {
        disko.devices = {
          disk = {
            main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    priority = 1;
                    name = "ESP";
                    start = "1M";
                    end = "512M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  nix = {
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/nix";
                    };
                  };
                };
              };
            };
          };
          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=${cfg.rootSize}"
              "defaults"
              "mode=755"
            ];
          };
        };

        fileSystems."/nix" = {
          fsType = "ext4";
          autoResize = true;
        };

        services.francynox.growpart.main = {
          inherit (cfg) device;
          partition = 2;
          before = [ "systemd-growfs@nix.service" ];
        };
      };
    };
}
