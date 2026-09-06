{ inputs, ... }:
{
  flake.nixosModules.vm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.frablab.vm;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      options.frablab.vm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable VM hardware and disk configuration";
        };

        device = lib.mkOption {
          type = lib.types.str;
          default = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
          description = "Primary disk device for VM";
        };

        swapSize = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = 4096;
          description = "Size of swap file on /nix in MB, or null to disable swap";
        };

        rootSize = lib.mkOption {
          type = lib.types.str;
          default = "2G";
          description = "Size of tmpfs root mount";
        };
      };

      config = lib.mkIf cfg.enable {
        boot = {
          kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

          initrd.availableKernelModules = [
            "ata_piix"
            "uhci_hcd"
            "virtio_pci"
            "virtio_scsi"
            "sd_mod"
            "sr_mod"
            "virtio_blk"
            "virtio_net"
          ];

          kernelModules = [ "kvm-amd" ];

          loader = {
            systemd-boot = {
              enable = true;
              configurationLimit = lib.mkDefault 10;
              consoleMode = "max";
            };

            efi.canTouchEfiVariables = true;
            timeout = lib.mkDefault 8;
          };
        };

        swapDevices = lib.mkIf (cfg.swapSize != null) [
          {
            device = "/nix/swapfile";
            size = cfg.swapSize;
          }
        ];

        disko.devices = {
          disk.main = {
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
