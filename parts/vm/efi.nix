{
  flake.nixosModules.vm-efi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.frablab.vm.efi;
    in
    {
      options.frablab.vm.efi = {
        configurationLimit = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Maximum number of configurations to show in systemd-boot";
        };

        timeout = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Timeout in seconds for systemd-boot";
        };
      };

      config = {
        boot = {
          kernelPackages = pkgs.linuxPackages_latest;

          initrd = {
            availableKernelModules = [
              "ata_piix"
              "uhci_hcd"
              "virtio_pci"
              "virtio_scsi"
              "sd_mod"
              "sr_mod"
              "virtio_blk"
              "virtio_net"
            ];
          };

          kernelModules = [ "kvm-amd" ];

          loader = {
            systemd-boot = {
              enable = true;
              inherit (cfg) configurationLimit;
              consoleMode = "max";
            };

            efi.canTouchEfiVariables = true;

            inherit (cfg) timeout;
          };
        };
      };
    };
}
