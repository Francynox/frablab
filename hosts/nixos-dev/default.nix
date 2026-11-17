{ inputs, ... }:
{

  networking.hostName = "nixos-dev";

  imports = [
    inputs.vscode-server.nixosModules.default
    ./development.nix
  ];

  frablab = {
    homelab = {
      persistence = {
        directories = [
          "/var/lib/docker"
        ];
        users.admin = {
          directories = [
            "Projects"
            ".vscode-server"
            ".antigravity-server"
            ".antigravity-ide-server"
            ".gemini"
          ];
          files = [
            ".gitconfig"
          ];
        };
      };

      network.subnet = "mgmt";
    };

    base = {
      users = {
        admin = {
          extraGroups = [ "docker" ];
          exportDeploySshKey = true;
          passwordlessSudo = true;
        };
      };
    };
  };

  services.francynox.auto-update = {
    push-server.enable = true;
    dates = "*-*-* 02:00:00";
  };
}
