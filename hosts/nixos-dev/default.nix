{ inputs, ... }:
{

  networking.hostName = "nixos-dev";

  imports = [
    inputs.vscode-server.nixosModules.default
    ./development.nix
  ];

  frablab.homelab.persistence = {
    directories = [
      "/var/lib/docker"
    ];
  };

  frablab.base = {
    users = {
      enable = true;
      admin = {
        extraGroups = [ "docker" ];
        exportDeploySshKey = true;
        passwordlessSudo = true;
        persistence = {
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
    };
  };

  services.francynox.auto-update = {
    push-server.enable = true;
    dates = "*-*-* 02:00:00";
  };

  frablab.homelab.network.subnet = "mgmt";
}
